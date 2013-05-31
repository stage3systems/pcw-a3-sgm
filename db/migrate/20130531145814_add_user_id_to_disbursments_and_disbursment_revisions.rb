class AddUserIdToDisbursmentsAndDisbursmentRevisions < ActiveRecord::Migration
  def change
    add_column :disbursments, :user_id, :integer
    add_column :disbursment_revisions, :user_id, :integer
  end
end
