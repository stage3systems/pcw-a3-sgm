class Tenant < ActiveRecord::Base
  has_many :activity_codes
  has_many :cargo_types
  has_many :companies
  has_many :configurations
  has_many :disbursements
  has_many :disbursement_revisions
  has_many :offices
  has_many :pfda_views
  has_many :ports
  has_many :services
  has_many :service_updates
  has_many :tariffs
  has_many :terminals
  has_many :users
  has_many :vessels

  def self.for_request(request)
    name = request.host.split('.').first
    Tenant.find_by(name: name)
  end

  def customer_name
    if name.end_with? 'stg'
      return name[0..-4]
    end
    if name.end_with? 'test'
      return name[0..-5]
    end
    name
  end

  def uses_new_da_sync?
    ["sgm", "biehl", "nabsa", "argelan", "marval", "robertreford", "mta", "benline", "fillettegreen", "seaforth", "gmc", "normac", "wallem", "wallemgroup", "tormarshipping", "hbm"].member? self.customer_name
  end

  def is_monson?
    name.starts_with? 'monson'
  end

  def is_biehl?
    name.starts_with? 'biehl'
  end

  def named_services
    Service.where(tenant_id: self.id, port_id: nil, terminal_id: nil).order(:item)
  end

  def supports_named_services?
    ["sgm", "wallem", "wallemgroup", "biehl"].member? self.customer_name
  end

  def supports_free_text_items?
    false
  end

  def is_sgm?
    name.starts_with? 'sgm' or name.starts_with? 'sturrockgrindrod'
  end

  def terms_url(root)
    if terms and terms.start_with? 'http'
      terms
    else
      "#{root}#{terms}"
    end
  end

  def sync_with_aos
    sync_cargo_types()
    sync_vessels()
    sync_companies()
    sync_offices()
    sync_users()
    sync_ports()
  end

  def sync_cargo_types
    api = AosApi.new(self)
    api.each('cargoType') do |t|
      ct = self.cargo_types.where(remote_id: t['id']).first
      ct = self.cargo_types.where(
        maintype: t['type'],
        subtype: t['subtype'],
        subsubtype: t['subsubtype'],
        subsubsubtype: t['subsubsubtype']).first unless ct
      ct = CargoType.new unless ct
      ct.update_from_json(self, t)
      ct.save!
    end
  end

  def sync_vessels
    api = AosApi.new(self)
    api.each('vessel') do |v|
      next if v['name'] == 'TBN'
      vessel = self.vessels.where('remote_id = :id OR name ilike :name',
                                    id: v['id'], name: "#{v["name"]}").first
      next unless v['loa'] or (vessel and vessel.loa)
      next unless v['intlGrossRegisteredTonnage'] or (vessel and vessel.grt)
      next unless v['intlNetRegisteredTonnage'] or (vessel and vessel.nrt)
      next unless v['fullSummerDeadweight'] or (vessel and vessel.dwt)
      vessel = Vessel.new unless vessel
      vessel.update_from_json(self, v)
      vessel.save!
    end
  end

  def sync_companies
    api = AosApi.new(self)
    api.companies.each do |c|
      company = self.companies.where('remote_id = :id OR name ilike :name',
                                     id: c['id'], name: "#{c["name"]}").first
      company = Company.new unless company
      company.update_from_json(self, c)
      company.save!
    end
  end

  def sync_offices
    api = AosApi.new(self)
    agency_company_id = JSON.parse(api.query('company', {isAgency: true}).body)["data"]["company"].first["id"] rescue 1
    api.each('office', {agencyCompany: agency_company_id}) do |o|
      office = self.offices.where('remote_id = :id OR name ilike :name',
                                  id: o['id'], name: "#{o["name"]}").first
      office = Office.new unless office
      office.update_from_json(self, o)
      office.save!
    end
  end

  def sync_users
    api = AosApi.new(self)
    api.users.each do |u|
      user = self.users.where('remote_id = :id OR uid = :uid',
                              id: u['id'], uid: u['loginName']).first
      user = User.new unless user
      user.update_from_json(self, u)
      user.save!
    end
  end

  def sync_ports
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
    api = AosApi.new(self)
    api.each('officePort') do |op|
      aos_port = api.find("port", op['portId'])
      aos_office = api.find("office", op['officeId'])
      port = self.ports.where('remote_id = :id OR name ilike :name',
                              id: op['portId'],
                              name: "#{aos_port['name']}").first
      unless port
        port = Port.new
        port.tenant_id = self.id
        port.currency = currency
        port.tax = tax
      end
      port.remote_id = aos_port['id']
      port.name = aos_port['name']
      port.save!
      office = self.offices.where('remote_id = :id OR name ilike :name',
                                  id: op['officeId'],
                                  name: "#{aos_office['name']}").first
      unless office.port_ids.member? port.id
        office.ports << port
      end
    end
  end

  def use_service_key_as_activity_code?
    ["sgm", "wallem", "wallemgroup"].member? self.customer_name
  end
end
