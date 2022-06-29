class AddCommentsToDisbursmentRevisions < ActiveRecord::Migration
  def change
    add_column :disbursment_revisions, :comments, :hstore
  end
end
