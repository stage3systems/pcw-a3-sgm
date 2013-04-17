namespace :monson do
  namespace :import do
    require 'csv'
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
  end
end
