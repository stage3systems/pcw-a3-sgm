class AuthController < ApplicationController
  def check
    user = get_user() rescue nil
    user = { name: user[:db].full_name,
             rocket_name: user[:rocket][:username] } if user
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
    @domain = auth0_config[:domain]
    @client_id = auth0_config[:client_id]
    @tenant = auth0_config[:tenant]
    @connection = auth0_config[:connection]
    @rocket_url = auth0_config[:rocket_url]
    if browser_valid?
      render layout: "auth"
    else
      render "browser_check", layout: "auth"
    end
  end

  def logout
    session[:token] = nil
    @rocket_url = auth0_config[:rocket_url]
    @rocket_clear_token_on_logout = auth0_config[:rocket_clear_token_on_logout]
    render layout: "auth"
  end

  private
  def auth0_config
    @auth0_config ||= ProformaDA::Application.config.auth0
  end

  def client_secret
    @client_secret ||= Base64::urlsafe_decode64(auth0_config[:client_secret])
  end

  def get_user
    token = JWT.decode(params[:token], client_secret).first rescue nil
    return nil unless token
    puts "Got token"
    rocket_id = (token["sub"].split('|')[1]).to_i
    rocket_user = RocketApi.new.get_user(rocket_id)
    return nil unless rocket_user
    puts "Got rocket_user: #{rocket_user}"
    user = User.where(rocket_id: rocket_id, deleted: false).first rescue nil
    return nil unless user
    return {db: user, rocket: rocket_user, token: token}
  end

  def browser_valid?
    return false if params[:browser_check]
    not (browser.ie? and browser.version.to_i < 10 and params[:force].nil?)
  end
end
