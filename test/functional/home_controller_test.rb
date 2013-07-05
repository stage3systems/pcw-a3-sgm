require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "anonymous users must login" do
    get :index
    assert_response :redirect
  end

  test "logged users can see the dashboard" do
    log_in :admin
    get :index
    assert_response :success
    log_out
    log_in :operator
    get :index
    assert_response :success
    log_out
  end
end
