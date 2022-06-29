class CreateTenants < ActiveRecord::Migration
  def change
    create_table :tenants do |t|
      t.string :name
      t.string :display
      t.string :full_name
      t.string :aos_name
      t.string :favicon
      t.string :default_email
      t.string :logo
      t.string :terms
      t.integer :piwik_id
      t.string :aos_api_url
      t.string :aos_api_user
      t.string :aos_api_password
      t.string :aos_api_psk

      t.timestamps null: false
    end
  end
end
