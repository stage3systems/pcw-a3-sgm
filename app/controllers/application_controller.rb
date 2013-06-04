class ApplicationController < ActionController::Base
  protect_from_forgery
  #def after_sign_out_path_for(resource_or_scope)
    #MonsonDisbursments::Application.config.after_sign_out_path
  #end
  def ensure_admin
    if current_user.nil? or not current_user.admin?
      redirect_to root_path
    end
  end
end
