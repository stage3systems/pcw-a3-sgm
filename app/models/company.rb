class Company < ActiveRecord::Base
  default_scope -> {order('name ASC')}
  validates_presence_of :name
  has_many :disbursements

  extend Syncable

  def crystalize
    {
      "company_name" => name,
      "company_email" => email
    }
  end

  def update_from_json(data)
    self.remote_id = data['id']
    self.name = data['name']
    self.email = data['email'] if data['email']
  end
end
