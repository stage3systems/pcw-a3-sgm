class Service < ActiveRecord::Base
  include RankedModel
  attr_accessible :code, :item, :key, :port_id, :row_order, :terminal_id
  belongs_to :port
  belongs_to :terminal
  ranks :row_order, :with_same => [:port_id, :terminal_id]
end
