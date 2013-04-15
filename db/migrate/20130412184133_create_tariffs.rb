class CreateTariffs < ActiveRecord::Migration
  def change
    create_table :tariffs do |t|
      t.string :name
      t.string :document
      t.integer :user_id
      t.integer :port_id
      t.integer :terminal_id
      t.date :validity_start
      t.date :validity_end

      t.timestamps
    end
  end
end
