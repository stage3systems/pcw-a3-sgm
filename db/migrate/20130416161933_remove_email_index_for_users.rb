class RemoveEmailIndexForUsers < ActiveRecord::Migration
  def up
    remove_index :users, :email
  end

  def down
    add_index :users, :email
  end
end
