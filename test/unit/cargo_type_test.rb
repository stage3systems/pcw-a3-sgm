require 'test_helper'

class CargoTypeTest < ActiveSupport::TestCase
  test "qualifier" do
    t = CargoType.new
    assert t.qualifier.nil?
    t.maintype = 'Type'
    assert t.qualifier == 'Type'
    t.subtype = 'SubType'
    assert t.qualifier == 'SubType'
    t.subsubtype = 'SubSubType'
    assert t.qualifier == 'SubSubType'
    t.subsubsubtype = 'SubSubSubType'
    assert t.qualifier == 'SubSubSubType'
   end
end
