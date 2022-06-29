class AddTerminalsCountToPorts < ActiveRecord::Migration
  def up
    add_column :ports, :terminals_count, :integer, default: 0
    def Port.readonly_attributes; [] end
    Port.all.each do |p|
      p.terminals_count = p.terminals.count
      p.save!
    end
  end
  def down
    remove_column :ports, :terminals_count
  end
end
