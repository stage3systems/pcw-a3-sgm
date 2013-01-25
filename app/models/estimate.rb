class Estimate < ActiveRecord::Base
  serialize :data, ActiveRecord::Coders::Hstore
  attr_accessible :cargo_qty, :days_alongside, :loadtime, :port_id, :tugs_in, :tugs_out, :vessel_id
  belongs_to :port
  belongs_to :vessel

  def blah
    return "foo"
  end
end
