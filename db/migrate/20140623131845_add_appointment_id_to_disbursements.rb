class AddAppointmentIdToDisbursements < ActiveRecord::Migration
  def change
    add_column :disbursements, :appointment_id, :integer
  end
end
