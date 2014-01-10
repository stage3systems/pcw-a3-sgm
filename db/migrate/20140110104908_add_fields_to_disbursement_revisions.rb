class AddFieldsToDisbursementRevisions < ActiveRecord::Migration
  def up
    add_column :disbursement_revisions, :amount, :decimal
    add_column :disbursement_revisions, :currency_symbol, :string
    DisbursementRevision.reset_column_information
    ActiveRecord::Base.record_timestamps = false
    begin
      DisbursementRevision.all.each do |dr|
        dr.amount = dr.compute_amount
        dr.currency_symbol = dr.compute_currency_symbol
        dr.reference = dr.compute_reference
        dr.save!
      end
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
  end
  def down
    remove_column :disbursement_revisions, :amount
    remove_column :disbursement_revisions, :currency_symbol
  end
end
