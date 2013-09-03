class RenameDisbursmentTables < ActiveRecord::Migration
  def up
    rename_table :disbursments, :disbursements
    rename_table :disbursment_revisions, :disbursement_revisions
    rename_column :disbursement_revisions, :disbursment_id, :disbursement_id
    rename_index :disbursement_revisions, :disbursment_revisions_pkey, :disbursement_revisions_pkey
    rename_index :disbursements, :disbursments_pkey, :disbursements_pkey
  end

  def down
    rename_table :disbursements, :disbursments
    rename_table :disbursement_revisions, :disbursment_revisions
    rename_column :disbursment_revisions, :disbursement_id, :disbursment_id
    rename_index :disbursment_revisions, :disbursement_revisions_pkey, :disbursment_revisions_pkey
    rename_index :disbursments, :disbursements_pkey, :disbursments_pkey
  end
end
