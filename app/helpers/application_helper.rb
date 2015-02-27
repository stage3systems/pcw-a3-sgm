module ApplicationHelper

  def icon(name)
    "<i class=\"glyphicon glyphicon-#{name}\"></i>".html_safe
  end

  def current_user
    @current_user ||= User.from_token(session[:token])
  end

end
