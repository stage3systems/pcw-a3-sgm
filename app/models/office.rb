class Office < ActiveRecord::Base
  has_and_belongs_to_many :ports
  has_many :users
  belongs_to :tenant

  extend Syncable

  def crystalize(d)
    d['data'].merge!({
      "office_name" => name,
      "office_email" => email,
      "office_address1" => address_1,
      "office_address2" => address_2,
      "office_address3" => address_3
    })
  end

  def update_from_json(tenant, data)
    self.tenant_id = tenant.id
    self.remote_id = data["id"]
    self.name = data["name"]
    if data["address"]
      address_lines = data["address"].split("\r\n").map &:strip
      self.address_1 = address_lines.shift
      self.address_2 = address_lines.shift
      self.address_3 = address_lines.shift
    end
    self.email = data["email"] if data["email"]
  end
end
