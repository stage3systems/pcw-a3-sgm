class AddAnonymousViewsToDisbursmentRevisions < ActiveRecord::Migration
  def change
    add_column :disbursment_revisions, :anonymous_views, :integer, :default => 0
  end
end
