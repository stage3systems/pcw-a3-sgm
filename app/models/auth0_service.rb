class Auth0Service
  include ::Auth0::Api::AuthenticationEndpoints
  
  delegate :post, to: :class
  def initialize(cfg)
   
    @auth0_client ||= Auth0Client.new(
      client_id: cfg['client_id'],
      client_secret: cfg['client_secret'],
      domain: cfg['domain'],
      api_version: 2,
      timeout: 15 # optional, defaults to 10
    )
  end

  def auth(username, password)
    @auth0_client.login_with_resource_owner(
      username, password,
      realm: 'Username-Password-Authentication'
    )
  end
end
