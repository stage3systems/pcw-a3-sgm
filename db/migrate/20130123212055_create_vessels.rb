class CreateVessels < ActiveRecord::Migration
  def change
    create_table :vessels do |t|
      t.string :name
      t.decimal :loa
      t.decimal :grt
      t.decimal :nrt
      t.decimal :dwt

      t.timestamps
    end
  end
end
