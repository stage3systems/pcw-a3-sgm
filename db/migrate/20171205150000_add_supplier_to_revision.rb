class AddSupplierToRevision < ActiveRecord::Migration
    def change
      add_column :disbursement_revisions, :supplier_id, :hstore
      add_column :disbursement_revisions, :supplier_name, :hstore
    end
  end
  