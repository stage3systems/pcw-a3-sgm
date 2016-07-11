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
    desc "Migrate Monson tenant"
    task monson_tenant: :environment do
      m = Tenant.find_by(name: 'monson')
      if m.nil?
        m = Tenant.new({
          name: 'monson',
          display: 'Monson',
          full_name: 'Monson Agencies Autralia Pty Ltd',
          aos_name: 'Bridge',
          favicon: 'favicon_monson.png',
          default_email: 'accounts@monson.com.au',
          logo: 'monson_agency.png',
          terms: 'maa-terms.pdf',
          piwik_id: 2
        })
        m.save!
      end
      connection = ActiveRecord::Base.connection
      [ActivityCode, CargoType, Company, Configuration,
       DisbursementRevision, Disbursement,
       Office, PfdaView, Port, ServiceUpdate, Service,
       Tariff, Terminal, User, Vessel].each do |o|
         connection.execute("UPDATE #{o.table_name} SET tenant_id = #{m.id}")
       end
    end
    desc "Migrate MariTeam tenant from json dump"
    task mariteam_tenant: :environment do
      maps = {}
      def data_for_model(maps, klass, &blk)
        maps[klass.name] = {} unless maps[klass.name]
        klass.record_timestamps = false
        f = File.open("mariteam-json/#{klass.table_name}.json", "r")
        blk.call(JSON.parse(f.read()))
        klass.record_timestamps = true
      end
      m = Tenant.find_by(name: 'mariteam')
      if m.nil?
        m = Tenant.new({
          name: 'mariteam',
          display: 'MariTeam',
          full_name: 'MariTeam Shipping Agencies',
          aos_name: 'MariTeam AOS',
          favicon: 'mariteam_favicon.ico',
          default_email: 'agency.rotterdam@mariteam-shipping.com',
          logo: 'mariteam.png',
          terms: 'mariteam_agency_conditions.pdf',
          piwik_id: 9
        })
        m.save!
      end
      if not File.exists? "mariteam-json"
        puts "Missing mariteam-json import directory"
        next
      end
      # Straightforward models
      [Tax, Currency, ActivityCode, CargoType, Company, Configuration,
       Office, Port, User, Vessel].each do |klass|
        data_for_model(maps, klass) do |data|
          data.each do |d|
            id = d.delete("id")
            o = klass.new(d)
            o.tenant_id = m.id if klass.columns_hash["tenant_id"]
            o.save!
            maps[klass.name][id] = o.id
          end
        end
      end
      # The following models require some id patching
      # Ignore tariffs for now
      # office ports
      data_for_model(maps, OfficesPort) do |data|
        data.each do |d|
          office = m.offices.find(maps['Office'][d['office_id']])
          port = m.ports.find(maps['Port'][d['port_id']])
          unless office.port_ids.member? port.id
            office.ports << port
          end
        end
      end
      # terminals
      data_for_model(maps, Terminal) do |data|
        data.each do |d|
          port = m.ports.find(maps['Port'][d['port_id']])
          id = d.delete("id")
          d["port_id"] = port.id
          t = Terminal.new(d)
          t.tenant_id = m.id
          t.save!
          maps['Terminal'][id] = t.id
        end
      end
      # services
      data_for_model(maps, Service) do |data|
        data.each do |d|
          port = m.ports.find(maps['Port'][d['port_id']])
          terminal = m.terminals.find_by(id: maps['Terminal'][d['terminal_id']])
          user = m.users.find_by(id: maps['User'][d['user_id']])
          activity_code = m.activity_codes.find_by(id: maps['ActivityCode'][d['activity_code_id']])
          id = d.delete("id")
          d["port_id"] = port.id
          d["terminal_id"] = terminal.id if terminal
          d["user_id"] = user.id if user
          d["activity_code_id"] = activity_code.id if activity_code
          s = Service.new(d)
          s.tenant_id = m.id
          s.save!
          maps['Service'][id] = s.id
        end
      end
      # service updates
      data_for_model(maps, ServiceUpdate) do |data|
        data.each do |d|
          service = m.services.find_by(id: maps['Service'][d['service_id']])
          next if service.nil?
          user = m.users.find_by(id: maps['User'][d['user_id']])
          id = d.delete("id")
          d["service_id"] = service.id
          d["user_id"] = user.id if user
          su = ServiceUpdate.new(d)
          su.tenant_id = m.id
          su.save!
          maps['ServiceUpdate'][id] = su.id
        end
      end
      # disbursements
      current_rev_map = {}
      data_for_model(maps, Disbursement) do |data|
        Disbursement.skip_callback(:create, :before, :generate_publication_id)
        Disbursement.skip_callback(:create, :after, :create_initial_revision)
        data.each do |d|
          id = d.delete("id")
          d.delete("disbursement_revisions")
          d.delete("port")
          d.delete("terminal")
          d.delete("vessel")
          d.delete("company")
          d.delete("user")
          d.delete("office")
          port = m.ports.find(maps['Port'][d['port_id']])
          terminal = m.terminals.find_by(id: maps['Terminal'][d['terminal_id']])
          vessel = m.vessels.find_by(id: maps['Vessel'][d['vessel_id']])
          company = m.companies.find_by(id: maps['Company'][d['company_id']])
          user = m.users.find_by(id: maps['User'][d['user_id']])
          office = m.offices.find_by(id: maps['Office'][d['office_id']])
          current_revision_id = d.delete("current_revision_id")
          da = Disbursement.new(d)
          da.tenant_id = m.id
          da.port_id = port.id
          da.terminal_id = terminal.id if terminal
          da.vessel_id = vessel.id if vessel
          da.company_id = company.id if company
          da.user_id = user.id if user
          da.office_id = office.id if office
          da.save!
          current_rev_map[current_revision_id] = da.id
          maps['Disbursement'][id] = da.id
        end
      end
      # disbursement revisions
      data_for_model(maps, DisbursementRevision) do |data|
        data.each do |d|
          id = d.delete("id")
          disbursement = m.disbursements.find_by(id: maps['Disbursement'][d['disbursement_id']])
          next unless disbursement
          cargo_type = m.cargo_types.find_by(id: maps['CargoType'][d['cargo_type_id']])
          user = m.users.find_by(id: maps['User'][d['user_id']])
          dr = DisbursementRevision.new(d)
          dr.tenant_id = m.id
          dr.disbursement_id = disbursement.id
          dr.cargo_type_id = cargo_type.id if cargo_type
          dr.user_id = user.id if user
          dr.save!
          da_id = current_rev_map[id]
          if da_id
            Disbursement.record_timestamps = false
            da = m.disbursements.find(da_id)
            da.current_revision_id = dr.id
            da.save!
            Disbursement.record_timestamps = true
          end
          maps['DisbursementRevision'][id] = dr.id
        end
      end
      # pfda_views
      data_for_model(maps, PfdaView) do |data|
        data.each do |d|
          d.delete("id")
          dr = m.disbursement_revisions.find(maps['DisbursementRevision'][d["disbursement_revision_id"]])
          pv = PfdaView.new(d)
          pv.tenant_id = m.id
          pv.disbursement_revision_id = dr.id
          pv.save!
        end
      end
    end
  end
  namespace :aos_sync do
    desc "Import Cargo Types from AOS"
    task :cargo_types => :environment do
      Tenant.all.each do |tenant|
        api = AosApi.new(tenant)
        api.each('cargoType') do |t|
          ct = tenant.cargo_types.where(remote_id: t['id']).first
          ct = tenant.cargo_types.where(
            maintype: t['type'],
            subtype: t['subtype'],
            subsubtype: t['subsubtype'],
            subsubsubtype: t['subsubsubtype']).first unless ct
          ct = CargoType.new unless ct
          ct.update_from_json(tenant, t)
          ct.save!
        end
      end
    end
    desc "Import Offices from AOS"
    task :offices => :environment do
      Tenant.all.each do |tenant|
        api = AosApi.new(tenant)
        api.each('office', {agencyCompany: 1}) do |o|
          office = tenant.offices.where('remote_id = :id OR name ilike :name',
                                        id: o['id'], name: "#{o["name"]}").first
          office = Office.new unless office
          office.update_from_json(tenant, o)
          office.save!
        end
      end
    end
    desc "Import Vessels from AOS"
    task :vessels => :environment do
      Tenant.all.each do |tenant|
        api = AosApi.new(tenant)
        api.each('vessel') do |v|
          next if v['name'] == 'TBN'
          vessel = tenant.vessels.where('remote_id = :id OR name ilike :name',
                                        id: v['id'], name: "#{v["name"]}").first
          next unless v['loa'] or (vessel and vessel.loa)
          next unless v['intlGrossRegisteredTonnage'] or (vessel and vessel.grt)
          next unless v['intlNetRegisteredTonnage'] or (vessel and vessel.nrt)
          next unless v['fullSummerDeadweight'] or (vessel and vessel.dwt)
          vessel = Vessel.new unless vessel
          vessel.update_from_json(tenant, v)
          vessel.save!
        end
      end
    end
    desc "Import Companies from AOS"
    task :companies => :environment do
      Tenant.all.each do |tenant|
        api = AosApi.new(tenant)
        api.companies.each do |c|
          company = tenant.companies.where('remote_id = :id OR name ilike :name',
                                           id: c['id'], name: "#{c["name"]}").first
          company = Company.new unless company
          company.update_from_json(tenant, c)
          company.save!
        end
      end
    end
    desc "Import Users from AOS"
    task :users => :environment do
      Tenant.all.each do |tenant|
        api = AosApi.new(tenant)
        api.users.each do |u|
          user = tenant.users.where('remote_id = :id OR uid = :uid',
                                    id: u['id'], uid: u['loginName']).first
          user = User.new unless user
          user.update_from_json(tenant, u)
          user.save!
        end
      end
    end
    desc "Import Ports from AOS"
    task :ports => :environment do
      tax = Tax.find_by(code: '---')
      if tax.nil?
        tax = Tax.new(code: '---', name: 'Unset', rate: 0)
        tax.save!
      end
      currency = Currency.find_by(code: '---')
      if currency.nil?
        currency = Currenty.new(code: '---', name: 'Unset', symbol: '-')
        currency.save!
      end
      Tenant.all.each do |tenant|
        api = AosApi.new(tenant)
        api.each('officePort') do |op|
          aos_port = api.find("port", op['portId'])
          aos_office = api.find("office", op['officeId'])
          port = tenant.ports.where('remote_id = :id OR name ilike :name',
                                    id: op['portId'],
                                    name: "#{aos_port['name']}").first
          unless port
            port = Port.new
            port.tenant_id = tenant.id
            port.currency = currency
            port.tax = tax
          end
          port.remote_id = aos_port['id']
          port.name = aos_port['name']
          port.save!
          office = tenant.offices.where('remote_id = :id OR name ilike :name',
                                        id: op['officeId'],
                                        name: "#{aos_office['name']}").first
          unless office.port_ids.member? port.id
            office.ports << port
          end
        end
      end
    end
    desc "Sync all common data with AOS"
    task :all => [:cargo_types, :vessels, :companies, :offices, :users, :ports] do
    end
  end
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
          email = r[4].split(' ')[0]
          if o.email != email
            o.email = email
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
