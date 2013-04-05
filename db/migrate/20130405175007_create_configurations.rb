class CreateConfigurations < ActiveRecord::Migration
  def change
    create_table :configurations do |t|
      t.string :company_name
      t.string :company_address1
      t.string :company_address2
      t.string :bank_name
      t.string :bank_address1
      t.string :bank_address2
      t.string :swift_code
      t.string :bsb_number
      t.string :ac_number
      t.string :ac_name

      t.timestamps
    end
  end
end
