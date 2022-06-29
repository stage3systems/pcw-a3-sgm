class CleanupAgainEstimates < ActiveRecord::Migration
  def change
    remove_column :estimates, :cargo_qty
    remove_column :estimates, :days_alongside
    remove_column :estimates, :loadtime
    remove_column :estimates, :tugs_in
    remove_column :estimates, :tugs_out
  end
end
