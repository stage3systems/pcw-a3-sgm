class RocketApi
  include HTTParty
  base_uri("#{ProformaDA::Application.config.auth0[:rocket_url]}/users")
  basic_auth(
    ProformaDA::Application.config.auth0[:rocket_user],
    ProformaDA::Application.config.auth0[:rocket_password])

  def get_user(id)
    r = self.class.get("/#{id}")
    return nil if r.response.code != "200"
    return JSON.parse(r.body, {symbolize_names: true})
  end

end
