class Company < ActiveRecord::Base
  default_scope -> {order('name ASC')}
  validates_presence_of :name
  has_many :disbursements
  has_many :services
  belongs_to :tenant

  extend Syncable

  FIELDS=['name', 'email', 'prefunding_type', 'prefunding_percent', 'is_supplier']

  def crystalize(d)
    FIELDS.inject(d['data']) {|data,f| data["company_#{f}"] = self.send(f); data }
    d
  end

  def update_from_json(tenant, data)
    self.tenant_id = tenant.id
    self.remote_id = data['id']
    FIELDS.each do |f|
      d = data[f.camelize(:lower)]
      send("#{f}=", d) if d
    end
  end

  def self.aos_modify(tenant, data)
    c = Company.where(tenant_id: tenant.id, remote_id: data['id']).first
    c = Company.new if c.nil?
    c.update_from_json(tenant, data)
    c.save
  end
end
