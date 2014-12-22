class AddHintsToDisbursementRevisions < ActiveRecord::Migration
  def change
    add_column :disbursement_revisions, :hints, :hstore
  end
end
