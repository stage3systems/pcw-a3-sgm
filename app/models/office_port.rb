class OfficePort

  def self.aos_create(tenant, data)
    office = Office.find_by(tenant_id: tenant.id, remote_id: data['officeId'])
    port = Port.find_by(tenant_id: tenant.id, remote_id: data['portId'])
    return true if office.nil? or port.nil?
    unless office.ports.member? port
      office.ports << port
    end
    return true
  end

  def self.aos_delete(tenant, data)
    office = Office.find_by(tenant_id: tenant.id, remote_id: data['officeId'])
    port = Port.find_by(tenant_id: tenant.id, remote_id: data['portId'])
    return true if office.nil? or port.nil?
    if office.ports.member? port
      office.ports.delete(port)
    end
    return true
  end

end
