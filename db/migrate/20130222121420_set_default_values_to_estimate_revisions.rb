class SetDefaultValuesToEstimateRevisions < ActiveRecord::Migration
  def change
    change_column :estimate_revisions, :cargo_qty, :integer, :default => 0
    change_column :estimate_revisions, :loadtime, :integer, :default => 0
    change_column :estimate_revisions, :tugs_in, :integer, :default => 0
    change_column :estimate_revisions, :tugs_out, :integer, :default => 0
    change_column :estimate_revisions, :days_alongside, :integer, :default => 0
  end
end
