class Disbursment < ActiveRecord::Base
  default_scope conditions: "status_cd != 2"
  attr_accessible :company_id, :dwt, :grt, :loa, :nrt,
                  :port_id, :publication_id,
                  :status_cd, :tbn, :terminal_id, :vessel_id
  belongs_to :port
  belongs_to :terminal
  belongs_to :vessel
  belongs_to :company
  has_many :disbursment_revisions, :dependent => :destroy, :order => 'number ASC'
  validates_presence_of :port_id
  validates_presence_of :company_id
  validates_presence_of :vessel_id, :unless => :tbn?
  validates_presence_of :dwt, :grt, :loa, :nrt, :if => :tbn?
  validate :dwt, :numericality => true
  validate :grt, :numericality => true
  validate :nrt, :numericality => true
  validate :loa, :numericality => true
  before_create :generate_publication_id
  after_create :create_initial_revision

  as_enum :status, draft: 0, published: 1, deleted: 2

  def title
    "PFDA for #{self.vessel_name} in #{self.port.name}"
  end

  def current_revision
    self.disbursment_revisions.last
  end

  def publish
    self.published!
    self.save
  end

  def unpublish
    self.draft!
    self.save
  end

  def delete
    self.deleted!
    self.save
  end

  def vessel_name
    if tbn
      "TBN-#{self.company.name}"
    else
      self.vessel.name
    end
  end

  def crystalize_vessel
    if self.tbn?
      {
        "vessel_name" => self.vessel_name,
        "vessel_dwt" => self.dwt,
        "vessel_grt" => self.grt,
        "vessel_nrt" => self.nrt,
        "vessel_loa" => self.loa
      }
    else
      self.vessel.crystalize
    end
  end

  def next_revision
    cur = self.current_revision
    nxt = DisbursmentRevision.new(disbursment_id: self.id)
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
        nxt.fields[k] = nxt.fields.values.map {|v| v.to_i}.max+1
        nxt.codes[k] = cur.codes[k]
        nxt.descriptions[k] = cur.descriptions[k]
        nxt.compulsory[k] = false
      end
      # merge leagacy data
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

  private
  def generate_publication_id
    self.publication_id = UUIDTools::UUID.random_create.to_s
  end

  def create_initial_revision
    dr = DisbursmentRevision.new(disbursment_id: self.id)
    dr.number = 0
    dr.crystalize
    dr.compute
    dr.save
  end
end
