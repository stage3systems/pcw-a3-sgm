class AddAosIdToDisbursements < ActiveRecord::Migration
  def change
    add_column :disbursements, :aos_id, :integer
  end
end
