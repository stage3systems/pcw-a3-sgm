class AddPrefundingFieldsToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :prefunding_type, :string
    add_column :companies, :prefunding_percent, :integer
  end
end
