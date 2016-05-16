class IdentityApi
  include HTTParty
  base_uri("#{Rails.application.config.x.identity["url"]}/users")
  basic_auth(
    Rails.application.config.x.identity["user"],
    Rails.application.config.x.identity["password"])

  def get_user(id)
    r = self.class.get("/#{id}")
    return nil if r.response.code != "200"
    return JSON.parse(r.body, {symbolize_names: true})
  end
end
