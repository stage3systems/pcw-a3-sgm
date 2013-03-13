class AddCargoTypeIdToDisbursmentRevisions < ActiveRecord::Migration
  def change
    add_column :disbursment_revisions, :cargo_type_id, :integer
  end
end
