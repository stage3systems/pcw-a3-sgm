class Office < ActiveRecord::Base
  attr_accessible :address_1, :address_2, :address_3,
                  :fax, :name, :phone, :email, :remote_id
  has_and_belongs_to_many :ports
  has_many :users

  extend Syncable

  def crystalize
    {
      "office_name" => name,
      "office_email" => email,
      "office_address1" => address_1,
      "office_address2" => address_2,
      "office_address3" => address_3
    }
  end

  def update_from_json(data)
    self.remote_id = data["id"]
    self.name = data["name"]
    address_lines = data["address"].split("\r\n").map &:strip
    self.address_1 = address_lines.shift
    self.address_2 = address_lines.shift
    self.address_3 = address_lines.shift
    self.email = data["email"] if data["email"]
  end
end
