class AddActivityCodesToDisbursementRevisions < ActiveRecord::Migration
  def change
    add_column :disbursement_revisions, :activity_codes, :hstore
  end
end
