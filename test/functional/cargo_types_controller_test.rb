require 'test_helper'

class CargoTypesControllerTest < ActionController::TestCase
  setup do
    @one = cargo_types(:one)
    @two = cargo_types(:two)
    log_as_admin
  end

  def log_as_admin
    log_in :admin
  end

  def log_as_operator
    log_in :operator
  end

  test "operators cannot view cargo_types" do
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
    assert_not_nil assigns(:cts)
  end

  test "operators cannot enable and disable types" do
    log_out
    log_as_operator
    assert CargoType.find(@two.id).enabled
    post :enabled, ids: [@one.id]
    assert_response :redirect
    assert CargoType.find(@two.id).enabled
    log_out
    log_as_admin
  end

  test "admin can enable and disable types" do
    assert CargoType.find(@two.id).enabled
    post :enabled, ids: [@one.id]
    assert_response :success
    assert !CargoType.find(@two.id).enabled
    post :enabled, ids: [@one.id, @two.id]
    assert_response :success
    assert CargoType.find(@two.id).enabled
  end
end
