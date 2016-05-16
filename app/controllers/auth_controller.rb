class AuthController < ApplicationController
  def check
    user = get_user() rescue nil
    user = { name: user[:db].full_name,
             identity_name: user[:identity][:username] } if user
    render json: {user: user}
  end

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
    cfg = Rails.application.config.x.identity
    @domain = cfg["domain"]
    @client_id = cfg["auth0"]["client"]["id"]
    @tenant = cfg["tenant"]
    @connection = cfg["auth0"]["connection"]
    @identity_url = cfg["url"]
    if browser_valid?
      render layout: "auth"
    else
      render "browser_check", layout: "auth"
    end
  end

  def logout
    session[:token] = nil
    cfg = Rails.application.config.x.identity
    @identity_url = cfg["url"]
    @clear_token_on_logout = cfg["clear_token_on_logout"]
    render layout: "auth"
  end

  private
  def client_secret
    @client_secret ||= Base64::urlsafe_decode64(
      Rails.application.config.x.identity["auth0"]["client"]["secret"])
  end

  def get_user
    token = JWT.decode(params[:token], client_secret).first rescue nil
    return nil unless token
    identity_id = (token["sub"].split('|')[1]).to_i
    identity_user = IdentityApi.new.get_user(identity_id)
    return nil unless identity_user
    user = User.where(rocket_id: identity_id, deleted: false).first rescue nil
    return nil unless user
    return {db: user, identity: identity_user, token: token}
  end

  def browser_valid?
    return false if params[:browser_check]
    not (browser.ie? and browser.version.to_i < 10 and params[:force].nil?)
  end
end
