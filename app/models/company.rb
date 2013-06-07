class Company < ActiveRecord::Base
  attr_accessible :email, :name
  validates_presence_of :email, :name
  has_many :disbursments

  def crystalize
    {
      "company_name" => name,
      "company_email" => email
    }
  end
end
