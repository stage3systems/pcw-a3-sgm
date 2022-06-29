namespace :pce do
  namespace :migrate do
    desc "Migrate AOS configurations"
    task aos_configs: :environment do
      config = Rails.application.config_for(:aos_api)
      Tenant.all.each do |t|
        c = config[t]
        next unless c
        t.aos_api_url = c['url']
        t.aos_api_user = c['user']
        t.aos_api_password = c['password']
        t.aos_api_psk = c['psk']
        t.save!
      end
    end
  end 
  namespace :export do
    desc "Export to json"
    task all: :environment do
      dest = "pce-json-#{DateTime.now.to_i}"
      Dir.mkdir dest
      [ActivityCode, CargoType, Company, Configuration,
       Currency, DisbursementRevision, Disbursement,
       Office, OfficesPort, PfdaView, Port, ServiceUpdate, Service,
       Tariff, Tax, Terminal, User, Vessel].each do |t|
        File.open(File.join(dest, "#{t.table_name}.json"), "w") do |f|
          last = t.count-1
          f.write('[')
          t.find_each.with_index do |o, i|
            f.write(o.to_json)
            f.write(',') unless i == last
          end
          f.write(']')
        end
      end
    end
  end
end
