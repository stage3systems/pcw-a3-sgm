class AddTerminalIdToDisbursments < ActiveRecord::Migration
  def change
    add_column :disbursments, :terminal_id, :integer
  end
end
