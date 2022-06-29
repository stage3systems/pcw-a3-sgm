require 'test_helper'

class CompaniesControllerTest < ActionController::TestCase
  setup do
    @company = companies(:stage3)
    log_as_admin
  end

  def log_as_admin
    log_in :admin
  end

  def log_as_operator
    log_in :operator
  end

  test "operators cannot view companies" do
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
    assert_not_nil assigns(:companies_grid)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create company" do
    assert_difference('Company.count') do
      post :create, company: {name: 'test company', email: 'some@email.com' }
    end

    assert_redirected_to company_path(assigns(:instance))
  end

  test "should show company" do
    get :show, id: @company
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @company
    assert_response :success
  end

  test "should update company" do
    put :update, id: @company, company: {name: 'tested company'}
    assert_redirected_to company_path(assigns(:instance))
  end

  test "should destroy company" do
    assert_difference('Company.count', -1) do
      delete :destroy, id: @company
    end

    assert_redirected_to companies_path
  end

  test "search for company" do
    post :search, {format: :json, name: "Evax"}
    assert_response :success
  end
end
