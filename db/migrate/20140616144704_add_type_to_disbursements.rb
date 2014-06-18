class AddTypeToDisbursements < ActiveRecord::Migration
  def change
    add_column :disbursements, :type_cd, :integer, default: 0
  end
end
