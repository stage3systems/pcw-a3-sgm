class Vessel < ActiveRecord::Base
  default_scope -> {order('name ASC')}
  validates_presence_of :dwt, :grt, :loa, :name, :nrt
  has_many :disbursements

  extend Syncable

  def crystalize
    {
      "vessel_name" => self.name,
      "vessel_dwt" => self.dwt.to_s,
      "vessel_grt" => self.grt.to_s,
      "vessel_loa" => self.loa.to_s,
      "vessel_nrt" => self.nrt.to_s
    }
  end

  def update_from_json(data)
    self.remote_id = data['id']
    self.name = data['name']
    self.loa = data['loa'] if data['loa']
    self.nrt = data['intlNetRegisteredTonnage'] if data['intlNetRegisteredTonnage']
    self.grt = data['intlGrossRegisteredTonnage'] if data['intlGrossRegisteredTonnage']
    self.dwt = data['fullSummerDeadweight'] if data['fullSummerDeadweight']
  end
end
