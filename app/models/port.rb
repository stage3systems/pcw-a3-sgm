class Port < ActiveRecord::Base
  default_scope -> {order('ports.name ASC') }
  paginates_per 10
  validates_presence_of :name, :tax_id, :currency_id
  has_many :disbursements
  has_many :services, -> { where(terminal_id: nil).order('row_order ASC') }
  has_many :terminals, -> {order 'name ASC'}
  has_many :tariffs
  belongs_to :currency
  belongs_to :tax
  has_and_belongs_to_many :offices

  include ServiceHolderHelper

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

end
