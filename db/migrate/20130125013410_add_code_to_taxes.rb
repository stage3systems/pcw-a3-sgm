class AddCodeToTaxes < ActiveRecord::Migration
  def change
    add_column :taxes, :code, :string
  end
end
