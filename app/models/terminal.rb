class Terminal < ActiveRecord::Base
  belongs_to :port, counter_cache: true
  has_many :services, -> {order 'row_order ASC'}
  has_many :tariffs
  has_many :disbursements

  include ServiceHolderHelper

  def crystalize(d, skip_services=false)
    d['data']['terminal_name'] = self.name
    self.metadata.each {|k,v| d['data']["terminal_#{k}"] = v} if self.metadata
    crystalize_services(d) unless skip_services
    d
  end
end
