class AddCurrentRevisionToDisbursements < ActiveRecord::Migration
  def up
    add_column :disbursements, :current_revision_id, :integer
    Disbursement.reset_column_information
    ActiveRecord::Base.record_timestamps = false
    begin
      Disbursement.all.each do |d|
        d.current_revision_id = d.disbursement_revisions.last.id
        d.save!
      end
    ensure
      ActiveRecord::Base.record_timestamps = true
    end

  end

  def down
    remove_column :disbursements, :current_revision_id
  end
end
