class Vessel < ActiveRecord::Base
  default_scope order('name ASC')
  attr_accessible :dwt, :grt, :loa, :name, :nrt
  validates_presence_of :dwt, :grt, :loa, :name, :nrt
  has_many :disbursments

  def crystalize
    {
      "vessel_name" => self.name,
      "vessel_dwt" => self.dwt.to_s,
      "vessel_grt" => self.grt.to_s,
      "vessel_loa" => self.loa.to_s,
      "vessel_nrt" => self.nrt.to_s
    }
  end

end
