class AddDefaultConfiguration < ActiveRecord::Migration
  def up
    c = Configuration.new
    c.company_name = 'Monson Agencies Australia Pty Ltd'
    c.company_address1 = '7/96 Toolooa Street'
    c.company_address2 = 'Gladstone, QLD, 4680'
    c.bank_name = 'ANZ Bank Ltd'
    c.bank_address1 = '7 Queen Street'
    c.bank_address2 = 'Fremantle, Western Australia'
    c.swift_code = 'ANZBAU3M'
    c.bsb_number = '016-307'
    c.ac_number = '1077-33669'
    c.ac_name = 'Monson Agencies Australia Pty Ltd'
    c.save!
    data = c.crystalize
    DisbursementRevision.all.each do |r|
      r.data = r.data.merge(data)
      r.save!
    end
  end

  def down
    Configuration.where(company_name: 'Monson Agencies Australia Pty Ltd').destroy_all
  end
end
