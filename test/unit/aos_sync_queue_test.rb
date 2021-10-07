require 'test_helper'

class AosSyncQueueTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.new({
      name: 'sgmtest',
      aos_api_url: 'https://sgmtest.agencyops.net/api'
    })
    @api = AosSyncQueue.new(@tenant);
  end

  test "prepare_data will return data" do
    body = {id: 1, port_id: 3}
    data = @api.prepare_data('pcwDaRevision', body)

    assert_equal data[:url], "https://sgmtest.agencyops.net/api/v1/save/pcwDaRevision"
    assert_equal data[:tenant], @tenant.name
    assert_equal data[:data], body
  end

end
