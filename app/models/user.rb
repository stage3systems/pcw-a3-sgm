class User < ActiveRecord::Base

  extend Syncable

  has_many :services
  has_many :service_updates
  has_many :disbursements
  has_many :disbursement_revisions
  belongs_to :office
  belongs_to :tenant
  attr_accessor :login

  def authorized_ports
    return tenant.ports if office.nil? or office.name == "Head Office"
    return office.ports
  end

  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  def update_from_json(tenant, data)
    self.tenant_id = tenant.id
    self.remote_id = data['id']
    self.uid = data['loginName']
    self.first_name = data['firstName']
    self.last_name = data['lastName']
    o = Office.find_by(tenant_id: tenant.id, remote_id: data['officeId'])
    self.office_id = o.id if o
    if data['password']
      self.encrypted_password = data['password']
    end
    self.admin = is_admin_type(data['personType'])
    self.deleted = (data['personType'] == '(DELETED)')
    if tenant.name.starts_with? "sgm" and (data['personType'] == 'ACCOUNTING')
      self.deleted = true
    end
    self.auth0_id = data['authZeroId']
    self.rocket_id = data['authZeroId'].split('|')[1]
  end

  def is_admin_type(t)
    ['MANAGER/USER',
     'SYSTEM ADMINISTRATOR',
     'NAVARIK HIDDEN SUPERUSER'].member? t
  end

  def self.from_tenant_and_token(tenant, token)
    return nil unless token
    valid = (Time.at(token["exp"]) > DateTime.now) rescue false
    return nil unless valid
    rocket_id = (token["sub"].split('|')[1])
    auth0_id = token["sub"]
    self.where(tenant_id: tenant.id, rocket_id: rocket_id).first rescue self.where(tenant_id: tenant.id, auth0_id: auth0_id).first 
  end
end
