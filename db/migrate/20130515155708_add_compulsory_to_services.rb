class AddCompulsoryToServices < ActiveRecord::Migration
  def change
    add_column :services, :compulsory, :boolean, :default => true
  end
end
