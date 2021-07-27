require 'test_helper'

class AosSyncQueueTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.new({
      name: 'sgmtest',
      aos_api_url: 'https://sgmtest.agencyops.net/api'
    })
    @api = AosSyncQueue.new(@tenant);
  end

  # test "prepare_data will return data for save action" do
  #   body = {id: 1, port_id: 3}
  #   data = @api.prepare_data('pcwDaRevision', body, 'save')

  #   assert_equal data[:url], "https://sgmtest.agencyops.net/api/v1/save/pcwDaRevision"
  #   assert_equal data[:tenant], @tenant.name
  #   assert_equal data[:data], body
  # end

   test "prepare_data will return data for 'da' delete action" do
    body = {
        appointment_id: 12,
        nomination_id: 15
    }
    data = @api.prepare_data('pcw-da', body, 'delete')
    assert_equal data[:url], "https://sgmtest.agencyops.net/api/v1/delete/pcw-da/12/15"
    assert_equal data[:tenant], @tenant.name
    assert_equal data[:data], body
  end

end
