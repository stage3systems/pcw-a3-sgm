require 'test_helper'

class TenantTest < ActiveSupport::TestCase
  test "customer name" do
    t = Tenant.new({name: "monsonwhatever"})
    assert_equal "monson", t.customer_name
    t = Tenant.new({name: "unknown"})
    assert_equal "stage3", t.customer_name
  end
end
