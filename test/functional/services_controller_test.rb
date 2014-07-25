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
    get :new, port_id: @port.id, terminal_id: @terminal.id
    assert_response :success
  end

  test "port service lifecycle" do
    # create invalid service
    post :create, port_id: @port.id, service: {
              row_order: 0, compulsory: false}
    assert_response :success
    # create first service
    post :create, port_id: @port.id, service: {
      code: '{compute: function(ctx) {return 1000;},taxApplies: false}',
              item: 'Test', key: 'TST',
              row_order: 0, compulsory: false}
    ps1 = assigns(:service)
    assert_redirected_to port_services_path(@port)
    # view first service
    get :show, port_id: @port.id, id: ps1.id
    assert_response :success
    # create second service
    post :create, port_id: @port.id, service: {
      code: '{compute: function(ctx) {return 2000;},taxApplies: false}',
      item: 'Test 2', key: 'TST2',
      row_order: 1, compulsory: false
    }
    ps2 = assigns(:service)
    assert_redirected_to port_services_path(@port)
    # view second service
    get :show, port_id: @port.id, id: ps2.id
    assert_response :success
    # edit second service
    get :edit, port_id: @port.id, id: ps2.id
    assert_response :success
    # invalid edit
    post :update, port_id: @port.id, id: ps2.id,
                  service: {
                    item: 'Test 2 edited',
                    code: nil
                  }
    assert_response :success
    # successfull update
    post :update, port_id: @port.id, id: ps2.id,
                  service: {
                    item: 'Test 2 edited',
                    code: '{compute: function(ctx) {return 3000;}'+
                          ',taxApplies: true}'
                  }
    assert_redirected_to port_services_path(@port)
    # reorder resources
    get :index, port_id: @port.id
    services = assigns(:services)
    assert_equal services[0], ps1
    assert_equal services[1], ps2
    post :sort, port_id: @port.id, id: ps1.id, row_order_position: 10
    get :index, port_id: @port.id
    services = assigns(:services)
    assert_equal services[0], ps2
    assert_equal services[1], ps1
    # delete service
    delete :destroy, port_id: @port.id, id: ps2.id
    assert_redirected_to port_services_path(@port)
  end

  test "terminal service lifecycle" do
    # create invalid service
    post :create, port_id: @port.id, terminal_id: @terminal.id,
                  service: {row_order: 0, compulsory: false}
    assert_response :success
    # create first service
    post :create, port_id: @port.id, terminal_id: @terminal.id,
                  service: {
                    code: '{compute: function(ctx) {return 1000;}'+
                          ',taxApplies: false}',
                    item: 'Test', key: 'TST',
                    row_order: 0,
                    compulsory: false
                  }
    ts1 = assigns(:service)
    assert_redirected_to port_terminal_services_path(@port, @terminal)
    # view first service
    get :show, port_id: @port.id, terminal_id: @terminal.id, id: ts1.id
    assert_response :success
    # create second service
    post :create, port_id: @port.id, terminal_id: @terminal.id,
                  service: {
                    code: '{compute: function(ctx) {return 2000;}'+
                          ',taxApplies: false}',
                    item: 'Test 2', key: 'TST2',
                    row_order: 1, compulsory: false
                  }
    ts2 = assigns(:service)
    assert_redirected_to port_terminal_services_path(@port, @terminal)
    # view second service
    get :show, port_id: @port.id, terminal_id: @terminal.id, id: ts2.id
    assert_response :success
    # edit second service
    get :edit, port_id: @port.id, terminal_id: @terminal.id, id: ts2.id
    assert_response :success
    # invalid edit
    post :update, port_id: @port.id, terminal_id: @terminal.id, id: ts2.id,
                  service: {
                    item: 'Test 2 edited',
                    code: nil
                  }
    assert_response :success
    # successfull update
    post :update, port_id: @port.id, terminal_id: @terminal.id, id: ts2.id,
                  service: {
                    item: 'Test 2 edited',
                    code: '{compute: function(ctx) {return 3000;}'+
                          ',taxApplies: true}'
                  }
    assert_redirected_to port_terminal_services_path(@port, @terminal)
    # reorder resources
    get :index, port_id: @port.id, terminal_id: @terminal.id
    services = assigns(:services)
    assert_equal services[0], ts1
    assert_equal services[1], ts2
    post :sort, port_id: @port.id, terminal_id: @terminal.id,
                id: ts1.id, row_order_position: 10
    get :index, port_id: @port.id, terminal_id: @terminal.id
    services = assigns(:services)
    assert_equal services[0], ts2
    assert_equal services[1], ts1
    # delete service
    delete :destroy, port_id: @port.id, terminal_id: @terminal.id, id: ts2.id
    assert_redirected_to port_terminal_services_path(@port, @terminal)
  end
end
