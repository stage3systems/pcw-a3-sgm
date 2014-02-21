class CreatePfdaViews < ActiveRecord::Migration
  def change
    create_table :pfda_views do |t|
      t.text :user_agent
      t.string :browser
      t.string :browser_version
      t.string :ip
      t.boolean :pdf
      t.integer :disbursement_revision_id

      t.timestamps
    end
  end
end
