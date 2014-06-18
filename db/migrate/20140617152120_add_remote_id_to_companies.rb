class AddRemoteIdToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :remote_id, :integer
  end
end
