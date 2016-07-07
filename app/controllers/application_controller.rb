class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_timezone
  before_filter :ensure_tenant

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
    @current_user ||= User.from_tenant_and_token(current_tenant, session[:token])
  end

  def current_tenant
    @current_tenant ||= Tenant.for_request(request)
  end

  def ensure_tenant
    if current_tenant.nil?
      redirect_to landing_index_path
    end
  end
end
