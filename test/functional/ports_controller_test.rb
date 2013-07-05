require 'test_helper'

class PortsControllerTest < ActionController::TestCase
  setup do
    @port = ports(:newcastle)
    log_as_admin
  end

  def log_as_admin
    log_in :admin
  end

  def log_as_operator
    log_in :operator
  end

  test "operators cannot view ports" do
    log_out
    log_as_operator
    get :index
    assert_response :redirect
    log_out
    log_as_admin
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:ports)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create port" do
    assert_difference('Port.count') do
      post :create, port: {name: 'test', currency_id: 1, tax_id: 1  }
    end

    assert_redirected_to port_path(assigns(:port))
  end

  test "should show port" do
    get :show, id: @port
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @port
    assert_response :success
  end

  test "should update port" do
    put :update, id: @port, port: {  }
    assert_redirected_to port_path(assigns(:port))
  end

  test "should destroy port" do
    assert_difference('Port.count', -1) do
      delete :destroy, id: @port
    end

    assert_redirected_to ports_path
  end
end
