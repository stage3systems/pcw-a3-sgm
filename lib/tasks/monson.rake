namespace :monson do
  namespace :import do
    require 'csv'
    require 'json'
    desc "Import raw CSV cargo types"
    task :cargo_types => :environment do
      file = ENV['file'] || 'cargo_types.csv'
      if not File::exists? file
        puts "Couldn't open #{file}"
      else
        CargoType.delete_all
        CSV.read(file).each do |r|
          next if r[0] == "id"
          ct = CargoType.new({
            remote_id: r[0],
            maintype: r[1],
            subtype: r[2],
            subsubtype: r[3],
            subsubsubtype: r[4]
          })
          ct.save
        end
        puts "#{CargoType.count} cargo types imported"
      end
    end
    desc "Import raw CSV port"
    task :ports => :environment do
      file = ENV['file'] || 'monson_ports.csv'
      if not File::exists? file
        puts "Couldn't open #{file}"
      else
        port_names = Port.pluck(:name).map {|n| n.upcase}
        aud = Currency.find_by_code 'AUD'
        gst = Tax.find_by_code 'GST'
        CSV.read(file).each do |r|
          next if r[0] == "name"
          unless port_names.member? r[0]
            p = Port.new(name: r[0])
            p.currency = aud
            p.tax = gst
            p.save!
          end
        end
        puts "#{Port.count-port_names.length} ports imported"
      end
    end
    desc "Import raw CSV offices"
    task :offices => :environment do
      file = ENV['file'] || 'monson_offices.csv'
      if not File::exists? file
        puts "Couldn't open #{file}"
      else
        office_names = Office.pluck(:name)
        aud = Currency.find_by_code 'AUD'
        gst = Tax.find_by_code 'GST'
        CSV.read(file).each do |r|
          next if r[0] == 'OFFICE NAME'
          o = Office.find_by_name(r[0])
          if o.nil?
            o = Office.new(name: r[0])
            a = r[1].split("\n")
            a = a.slice(1,3) if a.length == 4
            a << "" if a.length == 2
            o.address_1 = a[0]
            o.address_2 = a[1]
            o.address_3 = a[2]
            o.phone = r[2]
            o.fax = r[3]
            o.save!
          end
          r[5].split(',').each do |p|
            p = p.upcase.strip
            puts "Looking for #{p}"
            port = Port.find_by_name(p.upcase)
            if port.nil?
              port = Port.new(name: p.upcase)
              port.tax = gst
              port.currency = aud
            end
            puts "Associated #{p} with #{o.name}"
            port.office = o
            port.save!
          end
        end
      end
    end
    desc "Import raw CSV users"
    task :users => :environment do
      file = ENV['file'] || 'monson_users.csv'
      if not File::exists? file
        puts "Couldn't open #{file}"
      else
        CSV.read(file).each do |r|
          next if r[0] == "NAME OF USER"
          u = User.find_by_uid(r[2])
          first_name, last_name = r[0].split(' ').map {|x| x.capitalize}
          pw = 'monson*'
          if u.nil?
            u = User.new({
              uid: r[2],
              first_name: first_name,
              last_name: last_name,
              password: pw,
              password_confirmation: pw,
              email: ""
            })
            u.save!
          end
          offices = {
            "ACCOUNTS" => Office.find_by_name("Head Office"),
            "FREMANTLE" => Office.find_by_name("Head Office"),
            "KARRATHA" => Office.find_by_name("Dampier Office"),
            "MACKAY" => Office.find_by_name("Mackay & Abbot Point Office"),
          }
          ["ADELAIDE", "BRISBANE", "BUNBURY", "GERALDTON",
           "GLADSTONE", "MELBOURNE", "NEWCASTLE", "ONSLOW",
           "PORT HEDLAND", "PORT KEMBLA", "PORT LINCOLN",
           "PORTLAND", "TOWNSVILLE"].each do |o|
            n = o.split(" ").map{|w| w.capitalize}.join(" ")
            offices[o] = Office.find_by_name("#{n} Office")
          end
          if u.office.nil?
            u.office = offices[r[1]]
            u.save!
          end
          if u.email != r[3]
            u.email = r[3]
            u.save!
          end
        end
        puts "Users imported"
      end
    end
    desc "Import json vessels"
    task :vessels => :environment do
      file = ENV['file'] || 'monson_vessels.json'
      if not File::exists? file
        puts "Couldn't open #{file}"
      else
        vs = File.open(file, "r") {|f| JSON.parse(f.read)}
        fields = ['loa', 'nrt', 'dwt', 'grt']
        vs.each do |v|
          vessel = Vessel.find_by_name(v['name'])
          if vessel.nil? and (fields-v.keys).empty?
            vessel = Vessel.new(name: v['name'])
            fields.each {|f| vessel.send("#{f}=", v[f])}
            vessel.save!
          end
        end
      end
    end
  end
end
