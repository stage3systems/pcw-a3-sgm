class AddBeamAndMouldedDepthToVessel < ActiveRecord::Migration
    def change
      add_column :vessels, :beam, :decimal
      add_column :vessels, :moulded_depth, :decimal
    end
  end