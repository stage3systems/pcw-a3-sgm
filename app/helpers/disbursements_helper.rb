module DisbursementsHelper
  def format_list(d,
                        make_bold=method(:make_bold),
                        make_small=method(:make_small),
                        nl="<br />",
                        make_bold_underline=method(:make_bold_underline))
    return d if d.class == String
    entries = (d.map do |e|
      next "" if e == nil
      next "" if e.kind_of?(Array)
      next e if e.class == String
      case e[:style]
        when :bold
          make_bold.call(e[:value])
        when :small
          make_small.call(e[:value])
        when :bold_underline
          make_bold_underline.call(e[:value])
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

  def make_bold_underline(v)
    content_tag :u, v
  end

end
