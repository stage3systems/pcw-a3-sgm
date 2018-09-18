class AddBeamAndMouldedDepthToDisbursement < ActiveRecord::Migration
    def change
      add_column :disbursements, :beam, :decimal
      add_column :disbursements, :moulded_depth, :decimal
    end
  end