class CreateDisbursments < ActiveRecord::Migration
  def change
    create_table :disbursments do |t|
      t.integer :port_id
      t.integer :vessel_id
      t.integer :company_id
      t.integer :status_cd, :default => 0
      t.string :publication_id
      t.boolean :tbn, :default => false
      t.decimal :grt
      t.decimal :nrt
      t.decimal :dwt
      t.decimal :loa

      t.timestamps
    end
  end
end
