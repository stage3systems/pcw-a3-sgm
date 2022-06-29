class Configuration < ActiveRecord::Base
  belongs_to :tenant

  def crystalize(d)
    d['data'].merge!({
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
    })
  end
end
