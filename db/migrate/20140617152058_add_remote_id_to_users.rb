class AddRemoteIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :remote_id, :integer
  end
end
