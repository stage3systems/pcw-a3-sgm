class AddEnabledToCargoTypes < ActiveRecord::Migration
  def change
    add_column :cargo_types, :enabled, :boolean, :default => false
  end
end
