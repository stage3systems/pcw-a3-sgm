module VesselsHelper
  def self.sbt_certified_from_string(sbt_certified_string)
    if sbt_certified_string.nil? or sbt_certified_string == ""
      nil
    elsif sbt_certified_string == "true"
      true
    else
      false
    end
  end
  def self.sbt_certified_display_from_string(sbt_certified_string)
    VesselsHelper.sbt_certified_display(
      VesselsHelper.sbt_certified_from_string(sbt_certified_string)
    )
  end

  def self.sbt_certified_display(sbt_certified)
    if sbt_certified.nil?
      "Not set"
    elsif !sbt_certified
      "No"
    else
      "Yes"
    end
  end
end