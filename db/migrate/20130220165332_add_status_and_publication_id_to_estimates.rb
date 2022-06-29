class AddStatusAndPublicationIdToEstimates < ActiveRecord::Migration
  def change
    add_column :estimates, :status_cd, :integer, :default => 0
    add_column :estimates, :publication_id, :string
  end
end
