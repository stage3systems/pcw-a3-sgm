class Disbursement < ActiveRecord::Base
  default_scope -> {where("status_cd != 2")}
  attr_accessor :tbn_template, :vessel_type, :vessel_subtype
  [:port, :terminal, :office, :vessel, :company, :user].each do |k|
    belongs_to k
  end
  belongs_to :current_revision, class_name: "DisbursementRevision"
  belongs_to :tenant
  has_many :disbursement_revisions,
           -> {order 'updated_at DESC'},
           dependent: :destroy
  validates_presence_of :type_cd, :port_id
  validates_presence_of :company_id, unless: "inquiry? or deleted?"
  validates_presence_of :vessel_id, :unless => :tbn?
  validates_presence_of :dwt, :grt, :loa, :nrt, :if => :tbn?
  validates_numericality_of :dwt, :grt, :nrt, :loa, :if => :tbn?
  before_create :generate_publication_id
  after_create :create_initial_revision

  as_enum :status, draft: 0, initial: 1, deleted: 2, close: 3,
                   inquiry: 4, final: 5, archived: 6

  as_enum :type, standard: 0, owners_husbandry: 1, bunker_call: 2,
                 cleaning: 3, spare_parts: 4, other: 5, blank: 6

  def title(full=false)
    "#{self.current_revision.data['vessel_name']} in #{self.port.name}"
  end

  def full_title
    t = self.title
    r = self.current_revision
    t += "/#{self.terminal.name}" if self.terminal
    t += " on #{I18n.l r.eta}" if r.eta
    t
  end

  def delete
    self.deleted!
    self.save
  end

  def aos_url
    if self.tenant.uses_new_da_sync?
      self.tenant.aos_api_url.sub(
        '/api',
        '/da/'+self.appointment_id.to_s+'/nomination/'+self.nomination_id.to_s)
    else
      self.tenant.aos_api_url.sub(
      '/api',
      '/disbursement/'+self.appointment_id.to_s)
    end
  end

  def next_revision
    cur = self.current_revision
    nxt = DisbursementRevision.new(tenant_id: self.tenant.id, disbursement_id: self.id)
    nxt.number = cur.number+1
    # copy over the previous revision parameters
    ["cargo_qty", "days_alongside", "loadtime", "eta",
     "voyage_number", "tugs_in", "tugs_out", "tax_exempt",
     "cargo_type_id"].each do |k|
      nxt.send("#{k}=", cur.send(k))
    end
    DisbursementRevision.hstore_fields.each do |f|
      nxt.send("#{f}=", cur.send(f) || {})
    end
    nxt.activity_codes = {} unless nxt.activity_codes
    nxt
  end

  def as_json(options={})
    super(:include => [:disbursement_revisions, :port])
  end

  def fill_nomination_data(nomination_id)
    nomination = AosNomination.from_tenant_and_aos_id(tenant, nomination_id)
    return unless nomination
    ['vessel', 'port', 'company',
     'appointment_id', 'nomination_reference'].each do |e|
      send("#{e}=", nomination.send(e))
    end
  end

  def charge_base
    {
      "appointmentId" => appointment_id,
      "nominationId" => nomination_id,
      "payeeId" => company.remote_id,
      "creatorId" => user.remote_id,
      "estimatePdfUuid" => publication_id,
      "status" => status.to_s.upcase,
    }
  end

  private
  def generate_publication_id
    self.publication_id = UUIDTools::UUID.random_create.to_s
  end

  def create_initial_revision
    dr = DisbursementRevision.new
    dr.disbursement = self
    dr.tenant_id = self.tenant_id
    dr.number = 0
    dr.user = self.user
    dr.tax_exempt = true
    d = Crystalizer.new(self).run()
    ['data', 'fields', 'descriptions', 'activity_codes',
     'compulsory', 'codes', 'hints', 'supplier_id', 'supplier_name'].each {|f| dr.send("#{f}=", d[f]) }
    ['overriden', 'values',
     'values_with_tax', 'comments'].each {|f| dr.send("#{f}=", {}) }
    disabled = {}
    self.port.services.each {|s| disabled[s.key] = "1" if s.disabled and not s.compulsory} if self.port
    self.terminal.services.each {|s| disabled[s.key] = "1" if s.disabled  and not s.compulsory} if self.terminal
    dr.disabled = disabled
    dr.compute
    dr.save
    self.current_revision_id = dr.id
    self.save
  end

end
