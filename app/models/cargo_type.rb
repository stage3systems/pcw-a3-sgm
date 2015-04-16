# encoding: utf-8
class CargoType < ActiveRecord::Base
  has_many :disbursement_revisions
  default_scope -> {order('maintype ASC, subtype ASC, subsubtype ASC, subsubsubtype ASC')}

  extend Syncable

  def display
    fn = self.maintype
    fn += " » #{self.subtype}" if self.subtype
    fn += " » #{self.subsubtype}" if self.subsubtype
    fn += " » #{self.subsubsubtype}" if self.subsubsubtype
    fn
  end

  def qualifier
    ts = [self.maintype, self.subtype, self.subsubtype, self.subsubsubtype]
    ts.compact.last
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
    self.remote_id = data['id']
    self.maintype = data['type']
    self.subtype = data['subtype']
    self.subsubtype = data['subsubtype']
    self.subsubsubtype = data['subsubsubtype']
  end

end
