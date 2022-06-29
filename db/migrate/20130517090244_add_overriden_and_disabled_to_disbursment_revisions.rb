class AddOverridenAndDisabledToDisbursmentRevisions < ActiveRecord::Migration
  def change
    add_column :disbursment_revisions, :overriden, :hstore
    add_column :disbursment_revisions, :disabled, :hstore
  end
end
