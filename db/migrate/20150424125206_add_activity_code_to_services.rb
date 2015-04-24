class AddActivityCodeToServices < ActiveRecord::Migration
  def change
    add_reference :services, :activity_code, index: true, foreign_key: true
  end
end
