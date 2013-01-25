class CreateEstimates < ActiveRecord::Migration
  def change
    create_table :estimates do |t|
      t.integer :port_id
      t.integer :vessel_id
      t.integer :tugs_in
      t.integer :tugs_out
      t.integer :cargo_qty
      t.integer :loadtime
      t.integer :days_alongside

      t.timestamps
    end
  end
end
