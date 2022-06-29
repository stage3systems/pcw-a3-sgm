class AddRocketIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :rocket_id, :integer
  end
end
