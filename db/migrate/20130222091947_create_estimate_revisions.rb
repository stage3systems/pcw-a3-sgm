class CreateEstimateRevisions < ActiveRecord::Migration
  def change
    create_table :estimate_revisions do |t|
      t.integer :estimate_id
      t.hstore :data
      t.hstore :fields
      t.hstore :descriptions
      t.hstore :values
      t.hstore :values_with_tax
      t.hstore :codes
      t.integer :number

      t.timestamps
    end
  end
end
