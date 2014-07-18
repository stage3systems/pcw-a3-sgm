class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :timeoutable, :trackable #:validatable

  extend Syncable

  has_many :services
  has_many :service_updates
  has_many :disbursements
  has_many :disbursement_revisions
  belongs_to :office
  attr_accessor :login


  #def self.find_for_saml(auth, signed_in_resource=nil)
    #user = User.where(:provider => auth.provider, :uid => auth.uid).first
    #unless user
      #user = User.create(provider: auth.provider,
                         #uid: auth.uid,
                         #email: auth.extra.raw_info.email,
                         #first_name: auth.extra.raw_info.firstName,
                         #last_name: auth.extra.raw_info.lastName,
                         #password: Devise.friendly_token[0, 20]
                        #)
    #end
    #user
  #end

  def active_for_authentication?
    super && !deleted
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login).downcase
      where(conditions).where(["lower(uid) = :value OR lower(email) = :value", { :value => login }]).first
    else
      where(conditions).first
    end
  end

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
    else
      self.password = 'monson*'
    end
    self.admin = is_admin_type(data['personType'])
    self.deleted = (data['personType'] == '(DELETED)')
  end

  def is_admin_type(t)
    ['MANAGER/USER',
     'SYSTEM ADMINISTRATOR',
     'NAVARIK HIDDEN SUPERUSER'].member? t
  end
end
