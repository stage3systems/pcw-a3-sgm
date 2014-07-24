class DisbursementRevision < ActiveRecord::Base
  belongs_to :disbursement
  belongs_to :cargo_type
  belongs_to :user
  has_many :views,
           -> {order 'created_at DESC'},
           class_name: "PfdaView"
  after_save :schedule_sync

  def field_keys
    self.fields.sort_by {|k,v| v.to_i}.map {|k,i| k}
  end

  def compute
    ctx = V8::Context.new
    ctx.eval(self.context)
    ctx.load(Rails::root.join("app/assets/javascripts/compute.js"))
    ctx.eval("parseCodes(ctx)");
    ctx.eval("compute(ctx)");
    self.data["total"] = ctx.eval("ctx.total")
    self.data["total_with_tax"] = ctx.eval("ctx.totalTaxInc")
    self.fields.keys.each do |k|
      self.values[k] = ctx.eval("ctx.values['#{k}']")
      self.values_with_tax[k] = ctx.eval("ctx.values_with_tax['#{k}']")
    end
    self.data_will_change!
    self.values_will_change!
    self.values_with_tax_will_change!
    self.reference = self.compute_reference
    self.amount = self.compute_amount
    self.currency_symbol = self.compute_currency_symbol
  end

  def context
    <<CTX
    var ctx = {
      services: #{self.field_keys.to_json},
      vessel: {
        nrt: #{self.data["vessel_nrt"]},
        grt: #{self.data["vessel_grt"]},
        dwt: #{self.data["vessel_dwt"]},
        loa: #{self.data["vessel_loa"]}
      },
      estimate: {
        eta: new Date(#{"\"" if self.eta}#{self.eta}#{"\"" if self.eta}),
        cargo_qty: #{self.cargo_qty || 0},
        tugs_in: #{self.tugs_in || 0},
        tugs_out: #{self.tugs_out || 0},
        loadtime: #{self.loadtime || 0},
        days_alongside: #{self.days_alongside || 0}
      },
      cargo_type: {
        type: "#{self.data["cargo_type"]}",
        subtype: "#{self.data["cargo_subtype"]}",
        subsubtype: "#{self.data["cargo_subsubtype"]}",
        subsubsubtype: "#{self.data["cargo_subsubsubtype"]}"
      },
      tax_rate: #{self.data["tax_rate"]},
      data: #{self.data.to_json},
      codes: #{self.codes.to_json},
      parsed_codes: {},
      values: #{self.values.to_json},
      values_with_tax: #{self.values_with_tax.to_json},
      comments: #{self.comments.to_json},
      compulsory: #{Hash[self.compulsory.map{|k,v| [k,v=="1"]}].to_json},
      disabled: #{Hash[self.disabled.map{|k,v| [k,v=="1"]}].to_json},
      overriden: #{self.overriden.to_json},
      computed: {},
      computed_with_tax: {}
    };
CTX
  end

  def disabled?(k)
    return self.disabled[k] == "1"
  end

  def compulsory?(k)
    return self.compulsory[k] == "1"
  end

  def tax_applies?(k)
    return false if self.tax_exempt?
    return self.values[k] != self.values_with_tax[k]
  end

  def crystalize
    p = self.disbursement.port.crystalize
    o = self.disbursement.office.crystalize rescue {}
    v = self.disbursement.crystalize_vessel
    c = self.disbursement.company.crystalize rescue {}
    conf = Configuration.last.crystalize
    t = self.disbursement.terminal.crystalize(
              (p["fields"].values.map{|v|v.to_i}.max||0)+1) rescue
        {
          "data" => {},
          "fields" => {},
          "descriptions" => {},
          "codes" => {},
          "compulsory" => {},
        }
    ct = self.cargo_type.crystalize rescue {}
    self.data = v.merge(p["data"]).merge(c).merge(o).merge(conf).merge(t["data"]).merge(ct)
    self.fields = p["fields"].merge(t["fields"])
    self.descriptions = p["descriptions"].merge(t["descriptions"])
    self.compulsory = p["compulsory"].merge(t["compulsory"])
    self.codes = p["codes"].merge(t["codes"])
    self.disabled = {}
    self.overriden = {}
    self.values = {}
    self.values_with_tax = {}
    self.comments = {}
  end

  def previous
    self.disbursement.disbursement_revisions.where(:number => self.number-1).first
  end

  def next
    self.disbursement.disbursement_revisions.where(:number => self.number+1).first
  end

  def compute_currency_symbol
    self.data['currency_symbol']
  end

  def compute_amount
    self.data[self.tax_exempt? ? 'total' : 'total_with_tax']
  end

  def email
    e = self.data['office_email']
    e = self.disbursement.office.email rescue nil if e.blank?
    e = self.user.email rescue nil if e.blank?
    e = ProformaDA::Application.config.tenant_default_email if e.blank?
    e
  end

  def compute_reference
    ref = "#{self.data['vessel_name']} - #{self.data['port_name']}#{ " - "+self.data['terminal_name'] if self.data.has_key? 'terminal_name' }#{ " - "+self.voyage_number.gsub('/', '') unless self.voyage_number.blank?} - #{(self.updated_at.to_date rescue Date.today).strftime('%d %b %Y').upcase} - #{self.disbursement.status.upcase rescue "DELETED"} - REV. #{self.number}"
    ref.gsub('/', '_')
  end

  def self.hstore_fields
    [:data, :fields, :descriptions, :comments, :compulsory,
     :disabled, :codes, :overriden, :values, :values_with_tax]
  end

  def sync_with_aos
    return unless self.disbursement.nomination_id
    api = AosApi.new
    charges = {}
    api.each('disbursement',
             {nominationId: self.disbursement.nomination_id}) do |c|
      charges[c['code']] = c
    end
    keys = self.fields.keys.select {|k| !self.disabled?(k) }
    keys.each do |k|
      c = charges[k]
      j = self.charge_to_json(k)
      api.save('disbursement', c ? c.merge(j) : j)
    end
    (charges.keys-keys).each do |k|
      api.delete('disbursement', charges[k]['id'])
    end
  end

  def charge_to_json(k)
    {
      "appointmentId" => self.disbursement.appointment_id,
      "nominationId" => self.disbursement.nomination_id,
      "payeeId" => self.disbursement.company.remote_id,
      "creatorId" => self.disbursement.user.remote_id,
      "modifierId" => self.user.remote_id,
      "grossAmount" => self.values_with_tax[k],
      "netAmount" => self.values[k],
      "estimateId" => self.disbursement_id,
      "estimatePdfUuid" => self.disbursement.publication_id,
      "description" => self.descriptions[k],
      "status" => self.disbursement.status.to_s.upcase,
      "code" => k,
      "reference" => self.reference,
      "sort" => self.fields[k].to_i,
      "taxApplies" => self.tax_applies?(k),
      "comment" => self.comments[k]
    }
  end

  def schedule_sync
    self.delay.sync_with_aos
  end

end
