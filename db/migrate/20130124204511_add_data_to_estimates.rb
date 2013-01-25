class AddDataToEstimates < ActiveRecord::Migration
  def change
    add_column :estimates, :data, :hstore
  end
end
