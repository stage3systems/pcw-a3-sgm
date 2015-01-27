class Port < ActiveRecord::Base
  default_scope -> {order('name ASC') }
  paginates_per 10
  validates_presence_of :name, :tax_id, :currency_id
  has_many :disbursements
  has_many :services, -> { where(terminal_id: nil).order('row_order ASC') }
  has_many :terminals, -> {order 'name ASC'}
  has_many :tariffs
  belongs_to :currency
  belongs_to :tax
  has_and_belongs_to_many :offices

  def crystalize(d, skip_services=false)
    d['data'].merge!({
      'port_name' => self.name,
      'tax_name' => self.tax.name,
      'tax_rate' => self.tax.rate,
      'tax_code' => self.tax.code,
      'currency_name' => self.currency.name,
      'currency_code' => self.currency.code,
      'currency_symbol' => self.currency.symbol
    })
    crystalize_services(d) unless skip_services
    d
  end

  private
  def crystalize_services(d)
    self.services.each do |s|
      d['fields'][s.key] = d['index']
      d['descriptions'][s.key] = s.item
      d['codes'][s.key] = s.code
      d['compulsory'][s.key] = s.compulsory ? '1': '0'
      d['hints'][s.key] = 'Port specific service'
      d['index'] += 1
    end
    d
  end

end
