class EmailAddress

  def self.aos_create(tenant, data)
    return true if not data['prime']
    e = self.get_entity(tenant, data)
    if e
      e.email = data['address']
      e.save!
    end
    true
  end

  def self.aos_modify(tenant, data)
    return self.aos_create(tenant, data)
  end

  def self.aos_delete(tenant, data)
    return true if not data['prime']
    e = self.get_entity(tenant, data)
    if e
      e.email = nil
      e.save!
    end
    true
  end

  def self.get_entity(tenant, data)
    if data['officeId']
      Office.find_by(tenant_id: tenant.id, remote_id: data['officeId'])
    elsif data['companyId']
      Company.find_by(tenant_id: tenant.id, remote_id: data['companyId'])
    else
      nil
    end
  end

end
