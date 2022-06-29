class ConvertDaysAlonsideToFloatInDisbursmentRevision < ActiveRecord::Migration
  def up
    change_column :disbursment_revisions, :days_alongside, :decimal, :default => "0.0"
  end

  def down
    change_column :disbursment_revisions, :days_alongside, :integer, :default => 0
  end
end
