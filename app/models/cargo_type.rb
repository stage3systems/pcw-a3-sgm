# encoding: utf-8
class CargoType < ActiveRecord::Base
  attr_accessible :maintype, :remote_id, :subsubsubtype, :subsubtype, :subtype
  has_many :disbursement_revisions
  default_scope -> {order('maintype ASC, subtype ASC, subsubtype ASC, subsubsubtype ASC')}

  def display
    fn = self.maintype
    fn += " » #{self.subtype}" if self.subtype
    fn += " » #{self.subsubtype}" if self.subsubtype
    fn += " » #{self.subsubsubtype}" if self.subsubsubtype
    fn
  end

  def crystalize
    {
      "cargo_type" => self.maintype,
      "cargo_subtype" => self.subtype,
      "cargo_subsubtype" => self.subsubtype,
      "cargo_subsubsubtype" => self.subsubsubtype,
      "cargo_type_display" => self.display
    }
  end

  def self.authorized
    self.where(enabled: true)
  end

  def update_from_json(data)
    remote_id = data['id']
    maintype = data['type']
    subtype = data['subtype']
    subsubtype = data['subsubtype']
    subsubsubtype = data['subsubsubtype']
  end

  def self.aos_create(t)
    ct = CargoType.new
    ct.update_from_json(t)
    ct.save
  end

  def self.aos_modify(t)
    ct = CargoType.where(remote_id: t['id']).first
    return false if ct.nil?
    ct.update_from_json(t)
    ct.save
  end

  def self.aos_delete(t)
    CargoType.where(remote_id: t['id']).delete_all
    true
  end

end
