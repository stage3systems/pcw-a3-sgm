require 'new_relic/agent/method_tracer'
class AosApi
  include ::NewRelic::Agent::MethodTracer
  include HTTParty

  def initialize(tenant)
    @tenant = tenant
  end

  def options
    {
      base_uri: "#{@tenant.aos_api_url}/v1",
      basic_auth: {
        username: @tenant.aos_api_user,
        password: @tenant.aos_api_password
      }
    }
  end

  def save(entity, body)
    self.class.post("/save/#{entity}",
      options.merge({
        body: body.to_json,
        headers: {'Content-Type' => 'application/json'}
    }))
  end

  def delete(entity, id)
    self.class.get("/delete/#{entity}/#{id}", options)
  end

  def query(entity, query={})
    self.class.get("/#{entity}", options.merge(query: query))
  end

  def search(entity, query={})
    self.class.get("/search/#{entity}", options.merge(query: query))
  end

  def find(entity, id)
    resp = JSON.parse(self.class.get("/#{entity}/#{id}", options).body)
    resp["data"][entity].first
  end

  def first(entity, query={})
    resp = JSON.parse(self.class.get("/#{entity}", options.merge(query: query)).body)
    resp["data"][entity].first
  end

  def each(entity, query={})
    resp = JSON.parse(self.class.get("/#{entity}", options.merge(query: query)).body)
    count = 0
    page = 0
    total = resp["data"]["count"].to_i rescue 0
    while count < total do
      count += resp["data"][entity].length
      resp["data"][entity].each do |e|
        yield e
      end
      page += 1
      query["page"] = page
      resp = JSON.parse(self.class.get("/#{entity}", options.merge(query: query)).body) if count < total
    end
  end

  def users
    uu = []
    self.each('person', {companyId: stage3_company_id}) do |u|
      uu << u
    end
    self.each('person', {companyId: tenant_company_id}) do |u|
      uu << u
    end
    uu
  end

  def offices
    entities_with_email('office', {agencyCompany: 1})
  end

  def companies
    entities_with_email('company')
  end

  private
  def entities_with_email(entity, filter={})
    ee = []
    self.each(entity, filter) do |e|
      email = first('emailAddress', {"#{entity}Id" => e['id'], prime: 1}) rescue nil
      e['email'] = email['address'] if email
      ee << e
    end
    ee
  end

  def stage3_company_id
      return 32 if @tenant.customer_name == "transmarine"
      1
  end

  def tenant_company_id
      return 67 if @tenant.customer_name == "transmarine"
      return 2
  end
  add_method_tracer :get, 'Custom/aos_api-get'
  add_method_tracer :each, 'Custom/aos_api-each'
  add_method_tracer :save, 'Custom/aos_api-save'
end
