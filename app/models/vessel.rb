class Vessel < ActiveRecord::Base
  default_scope -> {order('name ASC')}
  validates_presence_of :dwt, :grt, :loa, :name, :nrt
  has_many :disbursements
  belongs_to :tenant

  extend Syncable

  def sbt_certified_display
    VesselsHelper.sbt_certified_display(self.sbt_certified)
  end

  def crystalize(d)
    d['data'].merge!({
      "vessel_name" => self.name,
      "vessel_dwt" => self.dwt.to_s,
      "vessel_grt" => self.grt.to_s,
      "vessel_loa" => self.loa.to_s,
      "vessel_nrt" => self.nrt.to_s,
      "vessel_imo" => self.imo_code.to_s,
      "vessel_type" => self.maintype.to_s,
      "vessel_subtype" => self.subtype.to_s,
      "vessel_sbt_certified" => self.sbt_certified.to_s,
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
    self.loa = self.parse_number(data['loa']) if data['loa']
    self.nrt = self.parse_number(data['intlNetRegisteredTonnage']) if data['intlNetRegisteredTonnage']
    self.grt = self.parse_number(data['intlGrossRegisteredTonnage']) if data['intlGrossRegisteredTonnage']
    self.dwt = self.parse_number(data['fullSummerDeadweight']) if data['fullSummerDeadweight']
    self.sbt_certified = data['sbtCertified'] if data['sbtCertified']
    self.imo_code = data['imoCode'] if data['imoCode']
    self.sbt_certified = data['sbtCertified']
  end

  def self.aos_modify(tenant, data)
    i = Vessel.where(tenant_id: tenant.id, remote_id: data['id']).first
    i = Vessel.new if i.nil? and valid_data(data)
    i.update_from_json(tenant, data)
    i.save
  end

  def parse_number(val)
    return val unless val.present?
    # remove thousand separator e.g. "1,684""
    val.to_s.tr(',','')
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
