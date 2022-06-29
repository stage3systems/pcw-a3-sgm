class AddNominationReferenceToDisbursements < ActiveRecord::Migration
  def change
    add_column :disbursements, :nomination_reference, :string
  end
end
