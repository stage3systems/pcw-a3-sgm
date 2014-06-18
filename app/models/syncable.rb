module Syncable
  def aos_create(data)
    i = self.new
    i.update_from_json(data)
    i.save
  end

  def aos_modify(data)
    i = self.where(remote_id: data['id']).first
    return false if i.nil?
    i.update_from_json(data)
    i.save
  end

  def aos_delete(data)
    self.where(remote_id: data['id']).delete_all
    true
  end
end
