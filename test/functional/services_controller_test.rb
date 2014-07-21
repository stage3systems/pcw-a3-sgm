require 'test_helper'

class ServicesControllerTest < ActionController::TestCase
  setup do
    @port = ports(:dummy)
    @terminal = terminals(:dummy)
    log_in :admin
  end

  test "operators cannot view services" do
    log_out
    log_in :operator
    get :index, port_id: @port.id
    assert_response :redirect
    log_out
    log_in :admin
  end

  test "should get index" do
    get :index, port_id: @port.id
    assert_response :success
    assert_not_nil assigns(:services)
  end

  test "should get index for teminal level services" do
    get :index, port_id: @port.id, terminal_id: @terminal.id
    assert_response :success
    assert_not_nil assigns(:services)
  end

  test "should get new" do
    get :new, port_id: @port.id
    assert_response :success
  end

  test "should create service" do
    assert_difference('@port.services.count') do
      post :create, port_id: @port.id, service: {
        code: '{compute: function(ctx) {return 0;},taxApplies: false}',
                item: 'Test', key: 'TST',
                row_order: 0, compulsory: false}
    end
    #assert_redirected_to services_path(assigns(:instance))
  end
end
