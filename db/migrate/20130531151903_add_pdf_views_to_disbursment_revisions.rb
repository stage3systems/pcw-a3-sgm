class AddPdfViewsToDisbursmentRevisions < ActiveRecord::Migration
  def change
    add_column :disbursment_revisions, :pdf_views, :integer, :default => 0
  end
end
