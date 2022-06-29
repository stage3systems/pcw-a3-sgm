class RemoveTaxFromCharges < ActiveRecord::Migration
  def change
    remove_column :charges, :tax_id
  end
end
