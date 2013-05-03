class DropCharges < ActiveRecord::Migration
  def up
    drop_table :charges
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
