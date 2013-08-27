class Office < ActiveRecord::Base
  attr_accessible :address_1, :address_2, :address_3,
                  :fax, :name, :phone, :email
  has_many :ports

  def crystalize
    {
      "office_name" => name,
      "office_email" => email,
      "office_address1" => address_1,
      "office_address2" => address_2,
      "office_address3" => address_3
    }
  end
end
