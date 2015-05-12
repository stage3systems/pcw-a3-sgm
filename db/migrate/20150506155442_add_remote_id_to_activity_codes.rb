class AddRemoteIdToActivityCodes < ActiveRecord::Migration
  def change
    add_column :activity_codes, :remote_id, :integer
  end
end
