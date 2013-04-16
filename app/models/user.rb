class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :timeoutable, :trackable, :validatable

  attr_accessor :login
  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me,
                  :uid, :provider, :first_name, :last_name, :admin, :login
  # attr_accessible :title, :body
  def self.find_for_saml(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      user = User.create(provider: auth.provider,
                         uid: auth.uid,
                         email: auth.extra.raw_info.email,
                         first_name: auth.extra.raw_info.firstName,
                         last_name: auth.extra.raw_info.lastName,
                         password: Devise.friendly_token[0, 20]
                        )
    end
    user
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login).downcase
      puts 'We had a login'
      where(conditions).where(["lower(uid) = :value OR lower(email) = :value", { :value => login }]).first
    else
      where(conditions).first
    end
  end

  def full_name
    "#{self.first_name} #{self.last_name}"
  end
end
