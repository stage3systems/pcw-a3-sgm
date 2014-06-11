class AddServicesCountToPorts < ActiveRecord::Migration
  def up
    add_column :ports, :services_count, :integer, default: 0
    def Port.readonly_attributes; [] end
    Port.all.each do |p|
      p.services_count = p.services.count
      p.save!
    end
  end
  def down
    remove_column :ports, :services_count
  end
end
