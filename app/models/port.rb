class Port < ActiveRecord::Base
  attr_accessible :name, :tax_id, :currency_id
  validates_presence_of :name, :tax_id, :currency_id
  has_many :charges, :order => 'row_order ASC'
  belongs_to :currency
  belongs_to :tax
end
