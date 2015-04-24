class CreateActivityCodes < ActiveRecord::Migration
  def change
    create_table :activity_codes do |t|
      t.string :code
      t.string :name

      t.timestamps null: false
    end
  end
end
