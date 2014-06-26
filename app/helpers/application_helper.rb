module ApplicationHelper
  def icon(name)
    "<i class=\"glyphicon glyphicon-#{name}\"></i>".html_safe
  end

  def fa_icon(name)
    "<i class=\"fa fa-#{name}\"></i>".html_safe
  end

  def configuration_tab?
    not ["home", "disbursements"].member? controller_name
  end

  def nan_to_zero(n)
    return 0 if n == 'NaN'
    return n
  end

  def ports_active?
    ['ports', 'tariffs', 'services', 'terminals'].member? controller_name
  end
end
