class AddIsSupplierToCompany < ActiveRecord::Migration
    def change
      add_column :companies, :is_supplier, :boolean
    end
  end
  