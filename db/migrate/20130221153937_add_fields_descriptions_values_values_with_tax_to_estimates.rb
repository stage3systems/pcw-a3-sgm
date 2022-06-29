class AddFieldsDescriptionsValuesValuesWithTaxToEstimates < ActiveRecord::Migration
  def change
    add_column :estimates, :fields, :hstore
    add_column :estimates, :descriptions, :hstore
    add_column :estimates, :values, :hstore
    add_column :estimates, :values_with_tax, :hstore
  end
end
