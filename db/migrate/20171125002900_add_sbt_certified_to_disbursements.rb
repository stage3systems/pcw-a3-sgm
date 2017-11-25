class AddSbtCertifiedToDisbursements < ActiveRecord::Migration
  def change
    add_column :disbursements, :sbt_certified, :boolean
  end
end