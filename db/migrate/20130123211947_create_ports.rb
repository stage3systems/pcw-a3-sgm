class CreatePorts < ActiveRecord::Migration
  def change
    create_table :ports do |t|
      t.string :name

      t.timestamps
    end
  end
end
