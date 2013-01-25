class Charge < ActiveRecord::Base
  include RankedModel
  attr_accessible :code, :key, :name, :port_id, :tax_id
  belongs_to :port
  ranks :row_order, :with_same => :port_id
  belongs_to :tax
end
