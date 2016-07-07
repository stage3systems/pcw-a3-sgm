require 'test_helper'

class ApiControllerTest < ActionController::TestCase

  test "ping" do
    get :ping
    assert_response :success
    assert_equal "pong", response.body
  end

  test "ping even without tenant" do
    request.host = 'unknown.test.host'
    get :ping
    assert_response :success
    assert_equal "pong", response.body
  end

  test "get nominations" do
    log_in :operator
    stub_request(:get, "https://test.agencyops.net/api/v1/search/nomination?action=nominations&controller=api&limit=10").
        with(basic_auth: ['test', 'test']).
        to_return(:status => 200, :body => "", :headers => {})
    get :nominations
    assert_response :success
    log_out
  end

  test "get nomination details" do
    log_in :operator
    stub_request(:get, "https://test.agencyops.net/api/v1/nomination/123").
        with(basic_auth: ['test', 'test']).
        to_return(aos_result(
                  :nomination, [{
                    appointmentId: 1234,
                    portId: 1,
                    vesselId: 1,
                    principalId: 1,
                    nominationNumber: 'A'
                  }]))

    stub_request(:get, "https://test.agencyops.net/api/v1/appointment/1234").
        with(basic_auth: ['test', 'test']).
        to_return(aos_result(:appointment, [{fileNumber: "123456789"}]))
    post :nomination_details, {format: :json, nomination_id: 123}
    assert_response :success
    log_out
  end

  test "get agency fees" do
    log_in :operator
    stub_request(:get, "https://test.agencyops.net/api/v1/agencyFee?companyId=123&dateEffectiveEnd=2015-01-09&dateExpiresStart=2015-01-09&portId=123").
      with(basic_auth: ['test', 'test']).
      to_return(aos_result(:agencyFee, [
        {id: 1,
         title: 'Generic',
         portId: nil,
         description: 'This is a generic valid fee'},
        {id: 2,
         title: 'Port Specific',
         portId: 1,
         description: 'This is a port specific fee'}
      ]))
    post :agency_fees, {format: :json, company_id: 123, port_id: 123, eta: "2015-01-09"}
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 2, data.length
    assert_equal "This is a port specific fee (Port Specific Fee)", data[1]['hint'] 
    log_out
  end

end
