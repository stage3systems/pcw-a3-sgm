class AddRemoteIdToVessels < ActiveRecord::Migration
  def change
    add_column :vessels, :remote_id, :integer
  end
end
