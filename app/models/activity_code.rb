class ActivityCode < ActiveRecord::Base
  has_many :services
  belongs_to :tenant

  def display
    "#{self.code} - #{self.name}"
  end

  def update_from_json(tenant, data)
    self.tenant_id = tenant.id
    self.remote_id = data['id']
    self.code = data['code']
    self.name = data['name']
  end

  def self.aos_create(tenant, data)
    a = self.find_by(tenant_id: tenant.id, code: data['code'])
    a = self.new unless a
    a.update_from_json(tenant, data)
    a.save
  end

  def self.aos_modify(tenant, data)
    i = self.where(tenant_id: tenant.id, remote_id: data['id']).first
    return false if i.nil?
    i.update_from_json(tenant, data)
    i.save
  end

  def self.aos_delete(tenant, data)
    self.where(tenant_id: tenant.id, remote_id: data['id']).delete_all
    true
  end
end
