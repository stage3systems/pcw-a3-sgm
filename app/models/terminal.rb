class Terminal < ActiveRecord::Base
  belongs_to :port, counter_cache: true
  has_many :services, -> {order 'row_order ASC'}
  has_many :tariffs
  has_many :disbursements

  def crystalize(d, skip_services=false)
    d['data']['terminal_name'] = self.name
    self.services.each do |s|
      d['fields'][s.key] = d['index']
      d['descriptions'][s.key] = s.item
      d['codes'][s.key] = s.code
      d['compulsory'][s.key] = s.compulsory ? '1' : '0'
      d['hints'][s.key] = 'Terminal specific service'
      d['index'] += 1
    end unless skip_services
    d
  end
end
