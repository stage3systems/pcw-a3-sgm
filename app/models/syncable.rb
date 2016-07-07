module Syncable
  def aos_create(tenant, data)
    i = self.new
    i.update_from_json(tenant, data)
    i.save
  end

  def aos_modify(tenant, data)
    i = self.where(tenant_id: tenant.id, remote_id: data['id']).first
    return false if i.nil?
    i.update_from_json(tenant, data)
    i.save
  end

  def aos_delete(tenant, data)
    self.where(tenant_id: tenant.id, remote_id: data['id']).delete_all
    true
  end
end
