class AddOfficeToPorts < ActiveRecord::Migration
  def change
    add_column :ports, :office_id, :integer
  end
end
