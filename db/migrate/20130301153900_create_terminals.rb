class CreateTerminals < ActiveRecord::Migration
  def change
    create_table :terminals do |t|
      t.integer :port_id
      t.string :name

      t.timestamps
    end
  end
end
