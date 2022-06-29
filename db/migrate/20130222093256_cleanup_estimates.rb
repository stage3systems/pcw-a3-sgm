class CleanupEstimates < ActiveRecord::Migration
  def change
    remove_column :estimates, :data
    remove_column :estimates, :fields
    remove_column :estimates, :descriptions
    remove_column :estimates, :values
    remove_column :estimates, :values_with_tax
  end
end
