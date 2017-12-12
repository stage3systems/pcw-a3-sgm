module ServiceHolderHelper
  def crystalize_services(d)
    self.services.each do |s|
      d['fields'][s.key] = d['index']
      d['supplier_id'][s.key] = s.company_id rescue nil
      d['supplier_name'][s.key] = s.company_id ? Company.find(s.company_id).name : nil
      d['descriptions'][s.key] = s.item
      d['codes'][s.key] = s.code
      d['activity_codes'][s.key] = s.activity_code.code rescue "MISC"
      d['compulsory'][s.key] = s.compulsory ? '1': '0'
      d['hints'][s.key] = "#{self.class.name} specific service"
      d['index'] += 1
    end
    d
  end
end
