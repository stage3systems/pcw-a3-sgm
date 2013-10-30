class AddVoyageNumberToDisbursementRevisions < ActiveRecord::Migration
  def change
    add_column :disbursement_revisions, :voyage_number, :string
  end
end
