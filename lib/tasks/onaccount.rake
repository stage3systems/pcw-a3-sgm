namespace :onaccount do
  desc "Import On Account Codes"
  task import: :environment do
    require 'roo'
    file = ENV['file'] || 'service_keys.xlsx'
    if not File::exists? file
      puts "Couldn't open #{file}"
      next
    end
    xlsx = Roo::Spreadsheet.open(file)
    codes_sheet = xlsx.sheet('On Account Activity Codes')
    codes_sheet.each(code: 'Code', name: 'Name') do |h|
      code = h[:code].strip
      next if code == 'Code'
      a = ActivityCode.find_or_initialize_by(code: code)
      a.name = h[:name].strip
      a.save!
    end
    a = ActivityCode.find_or_initialize_by(code: 'MISC')
    a.name = "Misc."
    a.save!
  end

  desc "Assign Activity Codes to Services"
  task assign_codes: :environment do
    require 'roo'
    file = ENV['file'] || 'service_keys.xlsx'
    if not File::exists? file
      puts "Couldn't open #{file}"
      next
    end
    xlsx = Roo::Spreadsheet.open(file)
    sheet = xlsx.sheet('Service Keys to Activity Codes')
    sheet.each(port: 'Port', terminal: 'Terminal Name',
               service_key: 'Service Key',
               code: 'On Account Activity Code') do |h|
      port = h[:port].strip
      next if port == 'Port'
      p = Port.find_by(name: port.upcase)
      key = h[:service_key].strip
      next if key == 'X'
      s = Service.where(key: key)
      s = s.where(port_id: p.id) if p
      terminal = h[:terminal].strip
      t = nil
      unless ['A', 'All'].member? terminal
        t = Terminal.find_by(name: terminal)
        t = Terminal.find_by(name: terminal.upcase) if t.nil?
      end
      s = s.where(terminal_id: t.id) if t
      s = s.first
      if s
        code = h[:code].strip rescue ''
        next if code == 'X'
        code = 'MISC' if code == '***'
        activity_code = ActivityCode.find_by(code: code)
        if activity_code
          s.activity_code_id = activity_code.id
          s.save!
          puts "Assigned #{code} to #{port}(#{p ? p.name : 'nil'}) / #{terminal}(#{t ? t.name : 'nil'}) / #{key} (id: #{s.id})"
        else
          puts "Activity code for #{code} not found"
        end
      else
        puts "Service #{key} not found in #{port} / #{terminal}"
      end
    end
  end
end
