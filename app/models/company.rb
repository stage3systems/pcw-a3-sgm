class Company < ActiveRecord::Base
  default_scope order('name ASC')
  attr_accessible :email, :name
  validates_presence_of :name
  has_many :disbursements

  def crystalize
    {
      "company_name" => name,
      "company_email" => email
    }
  end
end
