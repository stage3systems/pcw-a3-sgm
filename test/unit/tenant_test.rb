require 'test_helper'

class TenantTest < ActiveSupport::TestCase
  test "customer name" do
    t = Tenant.new({name: "monsontest"})
    assert_equal "monson", t.customer_name
    t = Tenant.new({name: "tenant"})
    assert_equal "tenant", t.customer_name
  end

  test "Use service key as activity code for Wallem PCW services" do
      t = Tenant.new({name: "wallem"})
      assert t.use_service_key_as_activity_code?

      t = Tenant.new({name: "wallemgroup"})
      assert t.use_service_key_as_activity_code?
  end

end
