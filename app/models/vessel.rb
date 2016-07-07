class Vessel < ActiveRecord::Base
  default_scope -> {order('name ASC')}
  validates_presence_of :dwt, :grt, :loa, :name, :nrt
  has_many :disbursements
  belongs_to :tenant

  extend Syncable

  def crystalize(d)
    d['data'].merge!({
      "vessel_name" => self.name,
      "vessel_dwt" => self.dwt.to_s,
      "vessel_grt" => self.grt.to_s,
      "vessel_loa" => self.loa.to_s,
      "vessel_nrt" => self.nrt.to_s,
      "vessel_imo" => self.imo_code.to_s,
      "vessel_type" => self.maintype.to_s,
      "vessel_subtype" => self.subtype.to_s
    })
  end

  def update_from_json(tenant, data)
    self.tenant_id = tenant.id
    if data['vesselTypeId']
      api = AosApi.new(tenant)
      t = api.find('vesselType', data['vesselTypeId'])
      self.maintype = t["type"] if t
      self.subtype = t["subtype"] if t
    end
    self.remote_id = data['id']
    self.name = data['name']
    self.loa = data['loa'] if data['loa']
    self.nrt = data['intlNetRegisteredTonnage'] if data['intlNetRegisteredTonnage']
    self.grt = data['intlGrossRegisteredTonnage'] if data['intlGrossRegisteredTonnage']
    self.dwt = data['fullSummerDeadweight'] if data['fullSummerDeadweight']
    self.imo_code = data['imoCode'] if data['imoCode']
  end

  def self.aos_modify(tenant, data)
    i = Vessel.where(tenant_id: tenant.id, remote_id: data['id']).first
    i = Vessel.new if i.nil? and valid_data(data)
    i.update_from_json(tenant, data)
    i.save
  end

  private
  def self.valid_data(data)
    missing = ['loa', 'intlNetRegisteredTonnage',
     'intlGrossRegisteredTonnage', 'fullSummerDeadweight'].map do |k|
      data[k].nil?
    end
    return false if missing.member? true
    true
  end
end
