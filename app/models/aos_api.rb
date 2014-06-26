class AosApi
  include HTTParty
  base_uri("#{ProformaDA::Application.config.aos_api_url}/v1")
  basic_auth(
    ProformaDA::Application.config.aos_api_user,
    ProformaDA::Application.config.aos_api_password)

  def initialize()
  end

  def cargoType(query={})
    self.class.get("/cargoType", query: query)
  end

  def port(query={})
    self.class.get("/port", query: query)
  end

  def save(entity, body)
    r = JSON.parse(
          self.class.post("/save/#{entity}",
                          body: body.to_json,
                          headers: {'Content-Type' => 'application/json'}).body)
    return nil if r["status"] != "success"
    return r["data"][entity][0]
  end

  def delete(entity, id)
    self.class.get("/delete/#{entity}/#{id}")
  end

  def query(entity, query={})
    self.class.get("/#{entity}", query: query)
  end

  def search(entity, query={})
    self.class.get("/search/#{entity}", query: query)
  end

  def find(entity, id)
    resp = JSON.parse(self.class.get("/#{entity}/#{id}").body)
    resp["data"][entity].first
  end

  def first(entity, query={})
    resp = JSON.parse(self.class.get("/#{entity}", query: query).body)
    resp["data"][entity].first
  end

  def each(entity, query={})
    resp = JSON.parse(self.class.get("/#{entity}", query: query).body)
    count = 0
    page = 0
    total = resp["data"]["count"].to_i
    while count < total do
      count += resp["data"][entity].length
      resp["data"][entity].each do |e|
        yield e
      end
      page += 1
      query["page"] = page
      resp = JSON.parse(self.class.get("/#{entity}", query: query).body)
    end
  end

  def users
    uu = []
    self.each('person', {companyId: 1}) do |u|
      uu << u
    end
    self.each('person', {companyId: 2}) do |u|
      uu << u
    end
    uu
  end

  def offices
    oo = []
    self.each('office', {agencyCompany: 1}) do |o|
      email = self.first('emailAddress', {officeId: o['id'], prime: 1}) rescue nil
      o['email'] = email["address"] if email
      oo << o
    end
    oo
  end

  def companies
    cc = []
    self.each('company') do |c|
      email = self.first('emailAddress', {companyId: c['id'], prime: 1}) rescue nil
      c['email'] = email["address"] if email
      cc << c
    end
    cc
  end

end
