class CreateServices < ActiveRecord::Migration
  def up
    create_table :services do |t|
      t.integer :port_id
      t.integer :terminal_id
      t.text :code
      t.string :item
      t.string :key
      t.integer :row_order

      t.timestamps
    end
    Charge.all.each do |c|
      s = Service.new
      s.code = c.code
      s.key = c.key
      s.item = c.name
      s.row_order = c.row_order
      s.port_id = c.port_id
      s.save
    end
  end

  def down
    drop_table :services
  end
end
