class Estimate < ActiveRecord::Base
  attr_accessible :port_id, :vessel_id
  belongs_to :port
  belongs_to :vessel
  has_many :estimate_revisions, :dependent => :destroy, :order => 'number ASC'
  validates_presence_of :port_id, :vessel_id
  before_create :generate_publication_id

  as_enum :status, draft: 0, published: 1, deleted: 2

  def title
    "Estimate for #{self.vessel.name} in #{self.port.name}"
  end

  def current_revision
    self.estimate_revisions.last
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

  private
  def generate_publication_id
    self.publication_id = UUIDTools::UUID.random_create.to_s
  end
end
