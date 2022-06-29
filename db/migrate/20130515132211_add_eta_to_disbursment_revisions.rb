class AddEtaToDisbursmentRevisions < ActiveRecord::Migration
  def change
    add_column :disbursment_revisions, :eta, :date
  end
end
