class Vessel < ActiveRecord::Base
  attr_accessible :dwt, :grt, :loa, :name, :nrt
  validates_presence_of :dwt, :grt, :loa, :name, :nrt
  after_destroy :delete_disbursments

  def crystalize
    {
      "vessel_name" => self.name,
      "vessel_dwt" => self.dwt.to_s,
      "vessel_grt" => self.grt.to_s,
      "vessel_loa" => self.loa.to_s,
      "vessel_nrt" => self.nrt.to_s
    }
  end

  def delete_disbursments
    Disbursment.where(:vessel_id => self.id).each {|d| d.delete }
  end

end
