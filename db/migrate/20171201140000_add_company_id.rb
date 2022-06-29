class AddCompanyId < ActiveRecord::Migration
    def change
      add_column :services, :company_id, :integer, foreign_key: true
    end
  end