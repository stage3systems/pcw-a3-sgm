class Disbursement < ActiveRecord::Base
  default_scope -> {where("status_cd != 2")}
  attr_accessor :tbn_template
  [:port, :terminal, :office, :vessel, :company, :user].each do |k|
    belongs_to k
  end
  belongs_to :current_revision, class_name: "DisbursementRevision"
  has_many :disbursement_revisions,
           -> {order 'updated_at DESC'},
           dependent: :destroy
  validates_presence_of :type_cd, :port_id
  validates_presence_of :company_id, unless: :inquiry?
  validates_presence_of :vessel_id, :unless => :tbn?
  validates_presence_of :dwt, :grt, :loa, :nrt, :if => :tbn?
  [:dwt, :grt, :nrt, :loa].each {|k| validate k, numericality: true}
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
    ProformaDA::Application.config.aos_api_url.sub(
      '/api',
      '/disbursement/'+self.appointment_id.to_s)
  end


  def crystalize
    p, t = crystalize_port_and_terminal
    d = {
      "data" => [crystalize_vessel,
                 p["data"],
                 crystalize_company,
                 crystalize_office,
                 Configuration.last.crystalize,
                 t["data"]].reduce(:merge)
    }
    ["fields", "descriptions", "compulsory", "codes"].each do |f|
      d[f] = p[f].merge(t[f])
    end
    d
  end

  def crystalize_port_and_terminal
    p = port.crystalize
    t = crystalize_terminal((p["fields"].values.map{|v|v.to_i}.max||0)+1)
    ['fields', 'descriptions', 'codes', 'compulsory'].each do |k|
      p[k] = {}
      t[k] = {}
    end if self.blank?
    [p, t]
  end

  def crystalize_office
    office.crystalize rescue {}
  end

  def crystalize_company
    company.crystalize rescue {}
  end

  def crystalize_terminal(n)
    terminal.crystalize(n) rescue
        {
          "data" => {},
          "fields" => {},
          "descriptions" => {},
          "codes" => {},
          "compulsory" => {},
        }
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
    nxt.update_schema(cur)
    nxt.compute
    nxt
  end

  def as_json(options={})
    super(:include => [:disbursement_revisions, :port])
  end

  def fill_nomination_data(nomination_id)
    nomination = AosNomination.from_aos_id(nomination_id)
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
    dr.number = 0
    dr.crystalize
    dr.compute
    dr.save
    self.current_revision_id = dr.id
    self.save
  end

end
