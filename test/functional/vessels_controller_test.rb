require 'test_helper'

class VesselsControllerTest < ActionController::TestCase
  setup do
    @vessel = vessels(:vesselone)
    log_as_admin
  end

  def log_as_admin
    log_in :admin
  end

  def log_as_operator
    log_in :operator
  end

  test "operators cannot view vessels" do
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
    assert_not_nil assigns(:vessels_grid)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create vessel" do
    assert_difference('Vessel.count') do
      post :create, vessel: {name: 'test vessel', loa: 100, grt: 10000, nrt: 10000, dwt: 10000 }
    end

    assert_redirected_to vessel_path(assigns(:vessel))
  end

  test "should show vessel" do
    get :show, id: @vessel
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @vessel
    assert_response :success
  end

  test "should update vessel" do
    put :update, id: @vessel, vessel: {name: 'tested vessel'}
    assert_redirected_to vessel_path(assigns(:vessel))
  end

  test "should destroy vessel" do
    assert_difference('Vessel.count', -1) do
      delete :destroy, id: @vessel
    end

    assert_redirected_to vessels_path
  end

  test "search for vessel" do
    post :search, {format: :json, name: 'vessel'}
    assert_response :success
  end
end
