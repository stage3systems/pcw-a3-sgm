class Tenant < ActiveRecord::Base
  has_many :activity_codes
  has_many :cargo_types
  has_many :companies
  has_many :configurations
  has_many :disbursements
  has_many :disbursement_revisions
  has_many :offices
  has_many :pfda_views
  has_many :ports
  has_many :services
  has_many :service_updates
  has_many :tariffs
  has_many :terminals
  has_many :users
  has_many :vessels

  def self.for_request(request)
    name = request.host.split('.').first
    Tenant.find_by(name: name)
  end

  def customer_name
    ['monson', 'mariteam', 'casper', 'fillettegreen'].each do |n|
      return n if name.starts_with? n
    end
    "stage3"
  end

  def is_monson?
    name.starts_with? 'monson'
  end
end
