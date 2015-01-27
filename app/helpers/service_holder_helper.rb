module ServiceHolderHelper
  def crystalize_services(d)
    self.services.each do |s|
      d['fields'][s.key] = d['index']
      d['descriptions'][s.key] = s.item
      d['codes'][s.key] = s.code
      d['compulsory'][s.key] = s.compulsory ? '1': '0'
      d['hints'][s.key] = "#{self.class.name} specific service"
      d['index'] += 1
    end
    d
  end
end
