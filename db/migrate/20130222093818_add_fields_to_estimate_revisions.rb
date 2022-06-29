class AddFieldsToEstimateRevisions < ActiveRecord::Migration
  def change
    add_column :estimate_revisions, :cargo_qty, :integer
    add_column :estimate_revisions, :days_alongside, :integer
    add_column :estimate_revisions, :loadtime, :integer
    add_column :estimate_revisions, :tugs_in, :integer
    add_column :estimate_revisions, :tugs_out, :integer
  end
end
