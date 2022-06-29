class AddCompulsoryToDisbursmentRevisions < ActiveRecord::Migration
  def change
    add_column :disbursment_revisions, :compulsory, :hstore
  end
end
