class CreateCargoTypes < ActiveRecord::Migration
  def change
    create_table :cargo_types do |t|
      t.integer :remote_id
      t.string :maintype
      t.string :subtype
      t.string :subsubtype
      t.string :subsubsubtype

      t.timestamps
    end
  end
end
