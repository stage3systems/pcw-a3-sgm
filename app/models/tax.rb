class Tax < ActiveRecord::Base
  validates_presence_of :name, :code, :rate
  has_many :ports
end
