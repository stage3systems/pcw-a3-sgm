require 'test_helper'

class TaxesControllerTest < ActionController::TestCase
  setup do
    @tax = taxes(:gst)
    log_as_admin
  end

  def log_as_admin
    log_in :admin
  end

  def log_as_operator
    log_in :operator
  end

  test "operators cannot view taxes" do
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
    assert_not_nil assigns(:taxes_grid)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tax" do
    assert_difference('Tax.count') do
      post :create, tax: {name: 'test tax', code: 'TT', rate: 0.1 }
    end

    assert_redirected_to tax_path(assigns(:tax))
  end

  test "should show tax" do
    get :show, id: @tax
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @tax
    assert_response :success
  end

  test "should update tax" do
    put :update, id: @tax, tax: {rate: 0.2}
    assert_redirected_to tax_path(assigns(:tax))
  end

  test "should destroy tax" do
    assert_difference('Tax.count', -1) do
      delete :destroy, id: @tax
    end

    assert_redirected_to taxes_path
  end
end
