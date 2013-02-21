class Estimate < ActiveRecord::Base
  serialize :data, ActiveRecord::Coders::Hstore
  attr_accessible :cargo_qty, :days_alongside, :loadtime,
                  :port_id, :tugs_in, :tugs_out, :vessel_id
  belongs_to :port
  belongs_to :vessel
  as_enum :status, draft: 0, published: 1, deleted: 2

  def title
    "Estimate for #{self.vessel.name} in #{self.port.name}"
  end

  def publish
    self.published!
    self.publication_id = UUIDTools::UUID.random_create.to_s
    self.save
  end
  
  def unpublish
    self.draft!
    self.publication_id = nil
    self.save
  end

  def delete
    self.deleted!
    self.save
  end
end
