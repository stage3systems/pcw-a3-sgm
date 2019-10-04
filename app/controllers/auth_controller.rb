class AuthController < ApplicationController
  def register
    ret = begin
      user = get_user()
      if user
        session[:token] = user[:token] rescue params[:token]
        {result: 'ok'}
      else
        {error: 'Unkown User'}
      end
    rescue
      {error: 'Invalid Token'}
    end
    render json: ret
  end

  def login
    cfg = Rails.application.config.x.auth0
    @domain = cfg["domain"]
    @client_id = cfg["client_id"]
    @tenant = current_tenant.name
    @connection = cfg["connection"]
    if browser_valid?
      render layout: "auth"
    else
      render "browser_check", layout: "auth"
    end
  end

  def logout
    cfg = Rails.application.config.x.auth0
    @domain = cfg["domain"]
    @client_id = cfg["client_id"]
    @connection = cfg["connection"]
    session[:token] = nil
    render layout: "auth"
  end

  private
	def jwks_hash
		@jwks_hash ||= compute_jwks_hash
	end

	def compute_jwks_hash
    jwks_raw = Net::HTTP.get URI("https://#{Rails.application.config.x.auth0['domain']}/.well-known/jwks.json")
    jwks_keys = Array(JSON.parse(jwks_raw)['keys'])
    Hash[
      jwks_keys
      .map do |k|
        [
          k['kid'],
          OpenSSL::X509::Certificate.new(
            Base64.decode64(k['x5c'].first)
          ).public_key
        ]
      end
    ]
	end

  def get_user
    auth0 = Rails.application.config.x.auth0
    token = JWT.decode(params[:token], nil, true,
                       algorithm: 'RS256',
                       iss: "https://#{auth0['domain']}/", verify_iss: true,
                       aud: auth0['client_id'], verify_aud: true) do |header|
			jwks_hash()[header['kid']]
    end.first rescue nil
    return nil unless token
    auth0_id = token["sub"]
    user = User.where(tenant_id: current_tenant.id,
                      auth0_id: auth0_id, deleted: false).first rescue nil
    return {db: user, token: token} if user
    rocket_id = (token["sub"].split('|')[1]).to_i
    user = User.where(tenant_id: current_tenant.id,
                      rocket_id: rocket_id, deleted: false).first rescue nil
    if user
      user.auth0_id = auth0_id
      user.save
      logger.info "Migrated user #{user.full_name} (#{auth0_id})"
      {db: user, token: token}
    end
  end

  def browser_valid?
    return false if params[:browser_check]
    not (browser.ie? and browser.version.to_i < 10 and params[:force].nil?)
  end
end
