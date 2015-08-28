class AuthController < ApplicationController
  def check
    client_secret = Base64::urlsafe_decode64(auth0_config[:client_secret])
    user = begin
      token = JWT.decode(params[:token], client_secret).first
      rocket_id = (token["sub"].split('|')[1]).to_i
      user = User.where(rocket_id: rocket_id, deleted: false).first rescue nil
      if user
        {name: user.full_name}
      else
        nil
      end
    rescue
      nil
    end
    render json: {user: user}
  end

  def register
    client_secret = Base64::urlsafe_decode64(auth0_config[:client_secret])
    ret = begin
      token = JWT.decode(params[:token], client_secret, true).first
      rocket_id = (token["sub"].split('|')[1]).to_i
      user = User.where(rocket_id: rocket_id, deleted: false).first rescue nil
      if user
        session[:token] = token
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
    render layout: "auth"
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
end
