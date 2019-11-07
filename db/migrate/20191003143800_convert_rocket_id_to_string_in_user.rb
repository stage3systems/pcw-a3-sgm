class ConvertRocketIdToStringInUser < ActiveRecord::Migration
    def up
        change_column :users, :rocket_id, :string, :default => ""
    end

    def down
        change_column :users, :rocket_id, :integer, :default => 0
    end
end
  