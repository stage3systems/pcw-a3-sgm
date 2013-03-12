class Terminal < ActiveRecord::Base
  attr_accessible :name, :port_id
  belongs_to :port
  has_many :services, :order => 'row_order ASC'
end
