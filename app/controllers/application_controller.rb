class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_timezone

  #def after_sign_out_path_for(resource_or_scope)
    #MonsonDisbursements::Application.config.after_sign_out_path
  #end
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
end
