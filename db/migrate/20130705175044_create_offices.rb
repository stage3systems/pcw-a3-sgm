class CreateOffices < ActiveRecord::Migration
  def change
    create_table :offices do |t|
      t.string :name
      t.string :address_1
      t.string :address_2
      t.string :address_3
      t.string :phone
      t.string :fax

      t.timestamps
    end
  end
end
