class AddTariffsCountToPorts < ActiveRecord::Migration
  def up
    add_column :ports, :tariffs_count, :integer, default: 0
    def Port.readonly_attributes; [] end
    Port.all.each do |p|
      p.tariffs_count = p.tariffs.count
      p.save!
    end
  end
  def down
    remove_column :ports, :tariffs_count
  end
end
