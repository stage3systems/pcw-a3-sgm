class AddMetadataToPortsAndTerminals < ActiveRecord::Migration
  def change
    add_column :ports, :metadata, :hstore
    add_column :terminals, :metadata, :hstore
  end
end
