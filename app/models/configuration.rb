class Configuration < ActiveRecord::Base
  attr_accessible :ac_name, :ac_number, :bank_address1, :bank_address2,
                  :bank_name, :bsb_number, :company_address1,
                  :company_address2, :company_name, :swift_code

  def crystalize
    {
      "from_name" => company_name,
      "from_address1" => company_address1,
      "from_address2" => company_address2,
      "bank_name" => bank_name,
      "bank_address1" => bank_address1,
      "bank_address2" => bank_address2,
      "swift_code" => swift_code,
      "bsb_number" => bsb_number,
      "ac_number" => ac_number,
      "ac_name" => ac_name
    }
  end
end
