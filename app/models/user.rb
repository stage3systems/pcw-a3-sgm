class User < ActiveRecord::Base

  extend Syncable

  has_many :services
  has_many :service_updates
  has_many :disbursements
  has_many :disbursement_revisions
  belongs_to :office
  attr_accessor :login

  def authorized_ports
    return Port if office.nil? or office.name == "Head Office"
    return office.ports
  end

  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  def update_from_json(data)
    self.remote_id = data['id']
    self.uid = data['loginName']
    self.first_name = data['firstName']
    self.last_name = data['lastName']
    o = Office.find_by(remote_id: data['officeId'])
    self.office_id = o.id if o
    if data['password']
      self.encrypted_password = data['password']
    end
    self.admin = is_admin_type(data['personType'])
    self.deleted = (data['personType'] == '(DELETED)')
    self.rocket_id = data['rocketId']
  end

  def is_admin_type(t)
    ['MANAGER/USER',
     'SYSTEM ADMINISTRATOR',
     'NAVARIK HIDDEN SUPERUSER'].member? t
  end

  def self.from_token(token)
    return nil unless token
    valid = (Time.at(token["exp"]) > DateTime.now) rescue false
    return nil unless valid
    rocket_id = (token["sub"].split('|')[1]).to_i
    self.where(rocket_id: rocket_id).first
  end
end
