class Terminal < ActiveRecord::Base
  attr_accessible :name, :port_id
  belongs_to :port, counter_cache: true
  has_many :services, -> {order 'row_order ASC'}
  has_many :tariffs
  has_many :disbursements

  def crystalize(offset=0)
    d = {
      "data" => {
        "terminal_name" => self.name,
      },
      "fields" => {},
      "descriptions" => {},
      "codes" => {},
      "compulsory" => {}
    }
    self.services.each_with_index do |c, i|
      d["fields"][c.key] = i+offset
      d["descriptions"][c.key] = c.item
      d["codes"][c.key] = c.code
      d["compulsory"][c.key] = c.compulsory ? "1" : "0"
    end
    d
  end
end
