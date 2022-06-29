class AddRemoteIdToPorts < ActiveRecord::Migration
  def change
    add_column :ports, :remote_id, :integer
  end
end
