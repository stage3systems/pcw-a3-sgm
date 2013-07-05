require 'test_helper'

class DisbursmentsControllerTest < ActionController::TestCase
  setup do
    @port = ports(:newcastle)
    @vessel = vessels(:vesselone)
    @company = companies(:evax)
  end

  test "anonymous users must login" do
    get :index
    assert_response :redirect
  end

  test "logged users can list disbursments" do
    log_in :admin
    get :index
    assert_response :success
    assert_not_nil assigns(:disbursments)
    log_out
    log_in :operator
    get :index
    assert_response :success
    assert_not_nil assigns(:disbursments)
    log_out
  end

  test "new disbursment" do
    log_in :admin
    get :new
    assert_response :success
    post :create, disbursment: {
      vessel_id: @vessel.id
    }
    assert_select 'form  div.alert-error', 'Please review the problems below:'
    assert_response :success
    assert_difference('Disbursment.count') do
      post :create, disbursment: {
        port_id: @port.id,
        vessel_id: @vessel.id,
        company_id: @company.id
      }
    end
  end
end
