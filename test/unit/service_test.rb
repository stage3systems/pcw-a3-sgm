require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
  test "code must be syntactically correct" do
    s = Service.new
    s.item = "Test"
    s.key = "TST"
    s.code = "{compute: function(ctx) return 0; }, taxApplies: false}"
    assert !s.save, "Cannot save bad code"
    assert_not_nil s.errors[:code]
    assert s.errors[:code][0].start_with? "Syntax Error: "
  end

  test "code must pass basic runtime checks" do
    s = Service.new
    s.item = "Test"
    s.key = "TST"
    s.code = "{compute: function(ctx) { return parseBoson(ctx.boson); }, taxApplies: false}"
    assert !s.save, "Cannot save bad code"
    assert_not_nil s.errors[:code]
    assert s.errors[:code][0].start_with? "Runtime Error: "
  end

  test "valid code passes" do
    s = Service.new
    s.item = "Test"
    s.key = "TST"
    s.code = "{compute: function(ctx) { return 0; }, taxApplies: false}"
    assert s.save, "Can save good code"
  end
end
