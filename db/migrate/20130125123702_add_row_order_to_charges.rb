class AddRowOrderToCharges < ActiveRecord::Migration
  def change
    add_column :charges, :row_order, :integer
  end
end
