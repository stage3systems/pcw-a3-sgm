class AddDisabledToServices < ActiveRecord::Migration
  def change
    add_column :services, :disabled, :boolean, default: false
  end
end
