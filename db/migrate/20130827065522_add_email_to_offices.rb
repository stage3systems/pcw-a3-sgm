class AddEmailToOffices < ActiveRecord::Migration
  def change
    add_column :offices, :email, :string
  end
end
