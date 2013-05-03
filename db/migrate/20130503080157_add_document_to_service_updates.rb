class AddDocumentToServiceUpdates < ActiveRecord::Migration
  def change
    add_column :service_updates, :document, :string
  end
end
