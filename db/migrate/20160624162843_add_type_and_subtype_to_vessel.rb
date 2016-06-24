class AddTypeAndSubtypeToVessel < ActiveRecord::Migration
  def change
    add_column :vessels, :maintype, :string
    add_column :vessels, :subtype, :string
  end
end
