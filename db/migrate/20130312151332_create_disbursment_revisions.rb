class CreateDisbursmentRevisions < ActiveRecord::Migration
  def change
    create_table :disbursment_revisions do |t|
      t.integer :disbursment_id
      t.hstore :data
      t.hstore :fields
      t.hstore :descriptions
      t.hstore :values
      t.hstore :values_with_tax
      t.hstore :codes
      t.boolean :tax_exempt, :default => false
      t.integer :number
      t.integer :cargo_qty, :default => 0
      t.integer :days_alongside, :default => 0
      t.integer :loadtime, :default => 0
      t.integer :tugs_in, :default => 0
      t.integer :tugs_out, :default => 0
      t.string :reference

      t.timestamps
    end
  end
end
