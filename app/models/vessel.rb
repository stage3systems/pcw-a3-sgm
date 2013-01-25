class Vessel < ActiveRecord::Base
  attr_accessible :dwt, :grt, :loa, :name, :nrt
  validates_presence_of :dwt, :grt, :loa, :name, :nrt
end
