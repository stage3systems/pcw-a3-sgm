require 'test_helper'

class TenantTest < ActiveSupport::TestCase
  test "customer name" do
    t = Tenant.new({name: "monsontest"})
    assert_equal "monson", t.customer_name
    t = Tenant.new({name: "tenant"})
    assert_equal "tenant", t.customer_name
  end
end
