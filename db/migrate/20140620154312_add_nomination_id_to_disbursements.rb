class AddNominationIdToDisbursements < ActiveRecord::Migration
  def change
    add_column :disbursements, :nomination_id, :integer
  end
end
