class AddRemoteIdToOffices < ActiveRecord::Migration
  def change
    add_column :offices, :remote_id, :integer
  end
end
