class DisbursementRevision < ActiveRecord::Base
  attr_accessible :cargo_qty, :codes, :data, :days_alongside, :descriptions,
                  :disbursement_id, :fields, :loadtime, :number, :reference,
                  :tax_exempt, :tugs_in, :tugs_out, :values, :values_with_tax,
                  :cargo_type_id, :comments, :eta, :compulsory, :disabled,
                  :overriden, :user_id, :anonymous_views, :pdf_views,
                  :voyage_number
  serialize :data, ActiveRecord::Coders::Hstore
  serialize :fields, ActiveRecord::Coders::Hstore
  serialize :descriptions, ActiveRecord::Coders::Hstore
  serialize :comments, ActiveRecord::Coders::Hstore
  serialize :compulsory, ActiveRecord::Coders::Hstore
  serialize :disabled, ActiveRecord::Coders::Hstore
  serialize :codes, ActiveRecord::Coders::Hstore
  serialize :overriden, ActiveRecord::Coders::Hstore
  serialize :values, ActiveRecord::Coders::Hstore
  serialize :values_with_tax, ActiveRecord::Coders::Hstore
  belongs_to :disbursement
  belongs_to :cargo_type
  belongs_to :user

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
        cargo_qty: #{self.cargo_qty},
        tugs_in: #{self.tugs_in},
        tugs_out: #{self.tugs_out},
        loadtime: #{self.loadtime},
        days_alongside: #{self.days_alongside}
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

  def crystalize
    p = self.disbursement.port.crystalize
    o = self.disbursement.office.crystalize rescue {}
    v = self.disbursement.crystalize_vessel
    c = self.disbursement.company.crystalize
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

  def currency_symbol
    self.data['currency_symbol']
  end

  def amount
    self.data[self.tax_exempt? ? 'total' : 'total_with_tax'].to_f
  end

  def email
    e = self.data['office_email']
    e = self.disbursement.office.email rescue nil if e.blank?
    e = self.user.email rescue nil if e.blank?
    e = "accounts@monson.com.au" if e.blank?
    e
  end

  def reference
    ref = "#{self.data['vessel_name']} - #{self.data['port_name']}#{ " - "+self.data['terminal_name'] if self.data.has_key? 'terminal_name' }#{ " - "+self.voyage_number unless self.voyage_number.blank?} - #{self.updated_at.to_date.strftime('%d %b %Y').upcase} - #{self.disbursement.status.upcase} - REV. #{self.number}"
  end
end
