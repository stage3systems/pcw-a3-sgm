class AddAuth0IdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :auth0_id, :string
  end
end
