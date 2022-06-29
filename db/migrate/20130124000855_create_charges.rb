class CreateCharges < ActiveRecord::Migration
  def change
    create_table :charges do |t|
      t.integer :port_id
      t.integer :tax_id
      t.text :code
      t.string :name
      t.string :key

      t.timestamps
    end
  end
end
