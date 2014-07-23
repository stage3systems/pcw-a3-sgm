class Disbursement < ActiveRecord::Base
  default_scope -> {where("status_cd != 2")}
  attr_accessor :tbn_template
  belongs_to :port
  belongs_to :terminal
  belongs_to :office
  belongs_to :vessel
  belongs_to :company
  belongs_to :user
  belongs_to :current_revision, class_name: "DisbursementRevision"
  has_many :disbursement_revisions,
           -> {order 'updated_at DESC'},
           dependent: :destroy
  validates_presence_of :type_cd
  validates_presence_of :port_id
  validates_presence_of :company_id, unless: :inquiry?
  validates_presence_of :vessel_id, :unless => :tbn?
  validates_presence_of :dwt, :grt, :loa, :nrt, :if => :tbn?
  validate :dwt, :numericality => true
  validate :grt, :numericality => true
  validate :nrt, :numericality => true
  validate :loa, :numericality => true
  before_create :generate_publication_id
  after_create :create_initial_revision

  as_enum :status, draft: 0, initial: 1, deleted: 2, close: 3,
                   inquiry: 4, final: 5, archived: 6

  as_enum :type, standard: 0, owners_husbandry: 1, bunker_call: 2,
                 cleaning: 3, spare_parts: 4, other: 5

  def title
    "#{self.current_revision.data['vessel_name']} in #{self.port.name}"
  end

  def delete
    self.deleted!
    self.save
  end

  def aos_url
    ProformaDA::Application.config.aos_api_url.sub(
      '/api',
      '/disbursement/'+self.appointment_id.to_s)
  end

  def crystalize_vessel
    if self.tbn?
      {
        "vessel_name" => "TBN-#{self.company.name rescue "NoPrincipal"}",
        "vessel_dwt" => self.dwt,
        "vessel_grt" => self.grt,
        "vessel_nrt" => self.nrt,
        "vessel_loa" => self.loa
      }
    else
      self.vessel.crystalize
    end
  end

  #def visible
    #[:inquiry, :initial, :close].member? self.status
  #end

  def next_revision
    cur = self.current_revision
    nxt = DisbursementRevision.new(disbursement_id: self.id)
    nxt.number = cur.number+1
    # copy the current revision parameters
    ["cargo_qty", "days_alongside", "loadtime", "eta",
     "tugs_in", "tugs_out", "tax_exempt", "cargo_type_id"].each do |k|
      nxt.send("#{k}=", cur.send(k))
    end
    nxt.crystalize
    # update the "schema"
    cur.fields.keys.each do |k|
      # copy custom services over
      if k.starts_with? "EXTRAITEM"
        nxt.fields[k] = nxt.fields.values.map {|v| v.to_i}.max+1 rescue 1
        nxt.codes[k] = cur.codes[k]
        nxt.descriptions[k] = cur.descriptions[k]
        nxt.compulsory[k] = false
      end
      # merge legacy data
      if nxt.fields.has_key?(k)
        nxt.comments[k] = cur.comments[k] if cur.comments
        nxt.disabled[k] = cur.disabled[k]
        nxt.overriden[k] = cur.overriden[k] if cur.overriden.has_key? k
      end
    end
    # compute the result
    nxt.compute
    nxt
  end

  def as_json(options={})
    super(:include => [:disbursement_revisions, :port])
  end

  def fill_nomination_data(nomination_id)
    return unless nomination_id
    api = AosApi.new
    n = api.find('nomination', nomination_id)
    a = api.find('appointment', n['appointmentId'])
    v = Vessel.where(remote_id: n['vesselId']).first rescue nil
    self.vessel = v
    if n['principalId']
      c = Company.where(remote_id: n['principalId']).first rescue nil
      self.company = c
    end
    p = Port.where(remote_id: n['portId']).first rescue nil
    self.port = p
    self.nomination_id = nomination_id
    self.appointment_id = n['appointmentId']
    self.nomination_reference = "#{a['fileNumber']}-#{n['nominationNumber']}"
  end

  private
  def generate_publication_id
    self.publication_id = UUIDTools::UUID.random_create.to_s
  end

  def create_initial_revision
    dr = DisbursementRevision.new
    dr.disbursement = self
    dr.number = 0
    dr.crystalize
    dr.compute
    dr.save
    self.current_revision_id = dr.id
    self.save
  end

end
