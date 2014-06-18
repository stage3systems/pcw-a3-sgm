class AddRemoteIdToTerminals < ActiveRecord::Migration
  def change
    add_column :terminals, :remote_id, :integer
  end
end
