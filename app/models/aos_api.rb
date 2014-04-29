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

  def query(entity, query={})
    self.class.get("/#{entity}", query: query)
  end
end
