class AuthController < ApplicationController
  def register
    client_secret = Base64::urlsafe_decode64(auth0_config[:client_secret])
    ret = begin
      token = JWT.decode(params[:token], client_secret).first
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
    render layout: "auth"
  end

  def logout
    session[:token] = nil
    redirect_to auth_login_url
  end

  private
  def auth0_config
    @auth0_config ||= ProformaDA::Application.config.auth0
  end
end
