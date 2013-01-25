class Tax < ActiveRecord::Base
  attr_accessible :name, :code, :rate
  validates_presence_of :name, :code, :rate
end
