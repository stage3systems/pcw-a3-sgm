class ActivityCode < ActiveRecord::Base
  has_many :services

  def display
    "#{self.code} - #{self.name}"
  end
end
