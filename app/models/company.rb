class Company < ActiveRecord::Base
  default_scope -> {order('name ASC')}
  validates_presence_of :name
  has_many :disbursements

  extend Syncable

  FIELDS=['name', 'email', 'prefunding_type', 'prefunding_percent']

  def crystalize
    FIELDS.inject({}) {|data,f| data["company_#{f}"] = self.send(f); data }
  end

  def update_from_json(data)
    self.remote_id = data['id']
    FIELDS.each do |f|
      d = data[f.camelize(:lower)]
      send("#{f}=", d) if d
    end
  end

end
