class CreateServiceUpdates < ActiveRecord::Migration
  def change
    create_table :service_updates do |t|
      t.integer :service_id
      t.integer :user_id
      t.text :old_code
      t.text :new_code
      t.text :changelog

      t.timestamps
    end
  end
end
