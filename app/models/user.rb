class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :omniauthable, :timeoutable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me,
                  :uid, :provider, :first_name, :last_name
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

  def full_name
    "#{self.first_name} #{self.last_name}"
  end
end
