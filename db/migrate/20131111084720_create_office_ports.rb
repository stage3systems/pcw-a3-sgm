class CreateOfficePorts < ActiveRecord::Migration
  def up
    create_table :offices_ports do |t|
      t.belongs_to :office
      t.belongs_to :port
    end
    Port.all.each do |p|
      o = Office.find(p.office_id) rescue nil
      p.offices << o if o
    end
    change_table :disbursements do |t|
      t.integer :office_id
    end
    Disbursement.all.each do |d|
      d.office_id = d.port.office_id if d.port
      d.save
    end
  end
  def down
    drop_table :offices_ports
    change_table :disbursements do |t|
      t.remove :office_id
    end
  end
end
