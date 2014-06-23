class EmailAddress

  def self.aos_create(data)
    return true if not data['prime']
    e = self.get_entity(data)
    if e
      e.email = data['address']
      e.save!
    end
    true
  end

  def self.aos_modify(data)
    return self.aos_create(data)
  end

  def self.aos_delete(data)
    return true if not data['prime']
    e = self.get_entity(data)
    if e
      e.email = nil
      e.save!
    end
    true
  end

  def self.get_entity(data)
    if data['officeId']
      Office.find_by(remote_id: data['officeId'])
    elsif data['companyId']
      Company.find_by(remote_id: data['companyId'])
    else
      nil
    end
  end

end
