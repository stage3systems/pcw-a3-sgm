class AddDocumentToServices < ActiveRecord::Migration
  def change
    add_column :services, :document, :string
  end
end
