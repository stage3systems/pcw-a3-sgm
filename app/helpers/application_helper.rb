module ApplicationHelper

  def icon(name)
    "<i class=\"glyphicon glyphicon-#{name}\"></i>".html_safe
  end

  def current_user
    @current_user ||= User.from_tenant_and_token(current_tenant, session[:token])
  end

  def current_tenant
    @current_tenant ||= Tenant.for_request(request)
  end
end
