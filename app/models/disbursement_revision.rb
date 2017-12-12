class DisbursementRevision < ActiveRecord::Base
  belongs_to :disbursement
  belongs_to :cargo_type
  belongs_to :user
  belongs_to :tenant
  has_many :views,
           -> {order 'created_at DESC'},
           class_name: "PfdaView"
  after_save :schedule_sync

  def sbt_certified_display
    VesselsHelper.sbt_certified_display_from_string(self.data["vessel_sbt_certified"])
  end

  def field_keys
    self.fields.sort_by {|k,v| v.to_i}.map {|k,i| k}
  end

  def delete_field(k)
    ['fields', 'codes', 'descriptions', 'supplier_id', 'supplier_name',
     'values', 'values_with_tax', 'hints', 'comments'].each do |s|
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

  def flag_changes
    # work around hstore driver issue
    data_will_change!
    values_will_change!
    values_with_tax_will_change!
  end

  def context
    LightTemplate.new(['disbursements', '_ctx.js.erb'], {revision: self}).render
  end

  def compulsory?(k)
    return self.compulsory[k] == "1"
  end

  def tax_applies?(k)
    return false if self.tax_exempt?
    return self.values[k] != self.values_with_tax[k]
  end

  def previous
    self.disbursement.disbursement_revisions.where(:number => self.number-1).first
  end

  def next
    self.disbursement.disbursement_revisions.where(:number => self.number+1).first
  end

  def update_status!
    self.data['status'] = self.disbursement.status_cd
    self.data_will_change!
    self.reference = compute_reference
    self.save
  end

  def compute_currency_symbol
    self.data['currency_symbol']
  end

  def compute_amount
    self.data[self.tax_exempt? ? 'total' : 'total_with_tax']
  end

  def compute_reference
    d = self.data
    nom_ref =  self.disbursement.nomination_reference
    elems = (['vessel_name', 'port_name', 'terminal_name'].map {|e| d[e]}).compact
    elems << self.voyage_number unless self.voyage_number.blank?
    elems << nom_ref unless nom_ref.blank?
    elems << self.date_updated
    elems << self.disbursement_status
    elems << "REV. #{self.number}"
    elems.join(' - ').gsub('/', '_')
  end

  def self.hstore_fields
    [:data, :fields, :descriptions, :activity_codes, :comments, :compulsory, :supplier_id, :supplier_name,
     :disabled, :hints, :codes, :overriden, :values, :values_with_tax]
  end

  def sync_with_aos
    aos_nom = AosNomination.from_tenant_and_aos_id(self.tenant, self.disbursement.nomination_id)
    return unless aos_nom
    aos_nom.sync_revision(self) unless ["sgm", "sgmtest"].member?(self.tenant.name)
    AosDa.new.sync(self) if ["sgm", "sgmtest"].member?(self.tenant.name)
  end

  def charge_to_json(k)
    {
      "modifierId" => self.user.remote_id,
      "grossAmount" => self.values_with_tax[k],
      "netAmount" => self.values[k],
      "estimateId" => self.disbursement_id,
      "description" => self.descriptions[k],
      "supplierId" => self.supplier_id[k],
      "supplierName" => self.supplier_name[k],
      "code" => k,
      "activityCode" => (self.activity_codes[k] rescue 'MISC'),
      "reference" => self.reference,
      "sort" => self.fields[k].to_i,
      "taxApplies" => self.tax_applies?(k),
      "comment" => self.comments[k],
      "disabled" => self.disabled[k] == "1",
      "revisionNumber" => self.number
    }
  end

  def schedule_sync
    return if self.number == 0
    self.delay.sync_with_aos
  end

  def date_updated
    (self.updated_at || DateTime.now.utc).strftime('%d %b %Y - %H%M%S').upcase
  end

  def disbursement_status
    self.disbursement.status.upcase rescue "DELETED"
  end

end
