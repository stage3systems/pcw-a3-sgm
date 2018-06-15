class AuthController < ApplicationController
  def register
    ret = begin
      user = get_user()
      if user
        session[:token] = user[:token]
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
    session[:token] = nil
    render layout: "auth"
  end

  private
  def client_secret
    @client_secret ||= Base64::urlsafe_decode64(
      Rails.application.config.x.auth0["client_secret"])
  end

  def get_user
    token = JWT.decode(params[:token], client_secret).first rescue nil
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
