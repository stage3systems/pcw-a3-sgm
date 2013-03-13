class Port < ActiveRecord::Base
  attr_accessible :name, :tax_id, :currency_id
  validates_presence_of :name, :tax_id, :currency_id
  has_many :services, :order => 'row_order ASC', conditions: {:terminal_id => nil}
  has_many :terminals
  belongs_to :currency
  belongs_to :tax


  def crystalize
    d = {
      data: {
        port_name: self.name,
        tax_name: self.tax.name,
        tax_rate: self.tax.rate,
        tax_code: self.tax.code,
        currency_name: self.currency.name,
        currency_code: self.currency.code,
        currency_symbol: self.currency.symbol
      },
      fields: {},
      descriptions: {},
      codes: {}
    }
    self.services.each_with_index do |c, i|
      d[:fields][c.key] = i
      d[:descriptions][c.key] = c.item
      d[:codes][c.key] = c.code
    end
    d
  end
end
