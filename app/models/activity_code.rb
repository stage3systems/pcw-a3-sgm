class ActivityCode < ActiveRecord::Base
  has_many :services

  def display
    "#{self.code} - #{self.name}"
  end

  def update_from_json(data)
    self.remote_id = data['id']
    self.code = data['code']
    self.name = data['name']
  end

  def self.aos_create(data)
    a = self.find_by(code: data['code'])
    a = self.new unless a
    a.update_from_json(data)
    a.save
  end

  def self.aos_modify(data)
    i = self.where(remote_id: data['id']).first
    return false if i.nil?
    i.update_from_json(data)
    i.save
  end

  def self.aos_delete(data)
    self.where(remote_id: data['id']).delete_all
    true
  end
end
