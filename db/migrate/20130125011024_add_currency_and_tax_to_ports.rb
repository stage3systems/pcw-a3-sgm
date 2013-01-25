class AddCurrencyAndTaxToPorts < ActiveRecord::Migration
  def change
    add_column :ports, :currency_id, :integer
    add_column :ports, :tax_id, :integer
  end
end
