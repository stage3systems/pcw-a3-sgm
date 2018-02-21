module DisbursementsHelper
  def format_list(d,
                        make_bold=method(:make_bold),
                        make_small=method(:make_small),
                        nl="<br />")
    return d if d.class == String
    entries = (d.map do |e|
      next "" if e == nil
      next e if e.class == String
      case e[:style]
        when :bold
          make_bold.call(e[:value])
        when :small
          make_small.call(e[:value])
        else e[:value]
      end
    end)
    return "" if entries.empty?
    (entries.join(nl) + nl).html_safe
  end

  def make_bold(v)
    content_tag :strong, v
  end

  def make_small(v)
    content_tag :small, v
  end

end
