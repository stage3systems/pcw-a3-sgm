module ApplicationHelper
  def icon(name)
    "<i class=\"icon-#{name}\"></i>".html_safe
  end

  def configuration_tab?
    not ["home", "disbursments"].member? controller_name
  end

  def configuration_url
    return ports_url if current_user.admin?
    vessels_url
  end

  def ports_active?
    ['ports', 'tariffs', 'services', 'terminals'].member? controller_name
  end
end
