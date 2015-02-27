class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_timezone

  def ensure_admin
    if current_user.nil? or not current_user.admin?
      redirect_to root_path
    end
  end

  def set_timezone
    tz = ActiveSupport::TimeZone[request.cookies["time_zone"] || "UTC"]
    tz = ActiveSupport::TimeZone["UTC"] if tz.nil?
    Time.zone = tz
  end

  def authenticate_user!
    if current_user.nil?
      redirect_to auth_login_path
    end
  end

  def current_user
    @current_user ||= User.from_token(session[:token])
  end

end
