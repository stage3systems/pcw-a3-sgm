class CreateVesselTypes < ActiveRecord::Migration
  def change
    create_table :vessel_types do |t|
      t.integer :remote_id
      t.string :vessel_type
      t.string :vessel_subtype
      t.timestamps
    end
  end
end
