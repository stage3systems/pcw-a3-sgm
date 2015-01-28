class AddImoCodeToVessels < ActiveRecord::Migration
  def change
    add_column :vessels, :imo_code, :integer
  end
end
