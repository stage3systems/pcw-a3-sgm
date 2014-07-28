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

  def delete_field(k)
    ['fields', 'codes', 'descriptions',
     'values', 'values_with_tax'].each do |s|
      self.send(s).delete(k)
    end
  end

  def compute
    ComputationContext.new(self).compute
    flag_changes
    self.reference = compute_reference
    self.amount = compute_amount
    self.currency_symbol = compute_currency_symbol
  end

  def update_schema(old)
    old.fields.keys.each do |k|
      import_extra_item(old, k) if k.starts_with? "EXTRAITEM"
      merge_legacy_data(old, k) if self.fields.has_key?(k)
    end
  end

  def import_extra_item(old, k)
    self.fields[k] = self.next_index
    self.codes[k] = old.codes[k]
    self.descriptions[k] = old.descriptions[k]
    self.compulsory[k] = false
  end

  def merge_legacy_data(old, k)
    self.comments[k] = old.comments[k] if old.comments
    self.disabled[k] = old.disabled[k]
    self.overriden[k] = old.overriden[k] if old.overriden.has_key? k
  end

  def next_index
    self.fields.values.map {|v| v.to_i}.max+1 rescue 1
  end

  def flag_changes
    # work around hstore driver issue
    data_will_change!
    values_will_change!
    values_with_tax_will_change!
  end

  def context
    LightTemplate.new(['disbursements', '_ctx.js.erb'], {revision: self}).render
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
    d = disbursement.crystalize
    ct = cargo_type.crystalize rescue {}
    self.data = d["data"].merge(ct)
    ['fields', 'descriptions',
     'compulsory', 'codes'].each {|f| send("#{f}=", d[f]) }
    ['disabled', 'overriden', 'values',
     'values_with_tax', 'comments'].each {|f| send("#{f}=", {}) }
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

  def compute_reference
    d = self.data
    elems = (['vessel_name', 'port_name', 'terminal_name'].map {|e| d[e]}).compact
    elems << self.voyage_number unless self.voyage_number.blank?
    elems << self.date_updated
    elems << self.disbursement_status
    elems << "REV. #{self.number}"
    elems.join(' - ').gsub('/', '_')
  end

  def self.hstore_fields
    [:data, :fields, :descriptions, :comments, :compulsory,
     :disabled, :codes, :overriden, :values, :values_with_tax]
  end

  def sync_with_aos
    aos_nom = AosNomination.from_aos_id(self.disbursement.nomination_id)
    return unless aos_nom
    aos_nom.sync_revision(self)
  end

  def charge_to_json(k)
    {
      "modifierId" => self.user.remote_id,
      "grossAmount" => self.values_with_tax[k],
      "netAmount" => self.values[k],
      "estimateId" => self.disbursement_id,
      "description" => self.descriptions[k],
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

  def date_updated
    (self.updated_at.to_date rescue Date.today).strftime('%d %b %Y').upcase
  end

  def disbursement_status
    self.disbursement.status.upcase rescue "DELETED"
  end

  def active_keys
    self.fields.keys.select {|k| !self.disabled?(k) }
  end
end
