require 'test_helper'

class DisbursementsControllerTest < ActionController::TestCase
  setup do
    @published = disbursements(:published)
    @port = ports(:newcastle)
    @vessel = vessels(:vesselone)
    @company = companies(:evax)
  end

  test "anonymous users must login" do
    get :index
    assert_response :redirect
  end

  test "logged users can list disbursements" do
    log_in :admin
    get :index
    assert_response :success
    assert_not_nil assigns(:disbursements)
    log_out
    log_in :operator
    get :index
    assert_response :success
    assert_not_nil assigns(:disbursements)
    log_out
  end

  test "new disbursement" do
    log_in :admin
    get :new
    assert_response :success
    post :create, disbursement: {
      vessel_id: @vessel.id
    }
    assert_select 'form  div.alert-danger', 'Please review the problems below:'
    assert_response :success
    assert_difference('Disbursement.count') do
      post :create, disbursement: {
        port_id: @port.id,
        vessel_id: @vessel.id,
        company_id: @company.id
      }
    end
    log_out
  end

  test "new from nomination_id" do
    log_in :operator
    stub_request(:get, "https://test:test@test.agencyops.net/api/v1/nomination/123").
        to_return(:status => 200, :body => {
                    data: {
                      nomination: [{
                        vesselId: 1,
                        principalId: 1,
                        portId: 1
                      }]
                    }
                  }.to_json, :headers => {})
    get :new, nomination_id: 123
    assert_response :success
    log_out
  end

  test "set status" do
    log_in :operator
    post :status, {id: @published.id, status: "final"}
    assert_response :redirect
    log_out
  end

  test "get nominations" do
    log_in :operator
    stub_request(:get, "https://test:test@test.agencyops.net/api/v1/search/nomination?action=nominations&controller=disbursements&limit=10").
        to_return(:status => 200, :body => "", :headers => {})
    get :nominations
    assert_response :success
    log_out
  end

  test "get nomination details" do
    log_in :operator
    stub_request(:get, "https://test:test@test.agencyops.net/api/v1/nomination/123").
        to_return(:status => 200, :body => {
          data: {
            count: 1,
            page: 0,
            nomination: [{
              portId: 1,
              vesselId: 1,
              principalId: 1
            }]
          }
        }.to_json, :headers => {})
    post :nomination_details, {format: :json, nomination_id: 123}
    assert_response :success
    log_out
  end
  test "search disbursements" do
    log_in :admin
    post :search, {format: :json, port_id: 1}
    assert_response :success
    log_out
  end

  test "view published disbursements" do
    # Page
    get :published, id: @published.publication_id
    assert_response :success
    # PDF
    file = Rails.root.join 'pdfs', "#{@published.current_revision.reference}.pdf"
    File.delete(file) rescue nil?
    get :published, {format: :pdf, id: @published.publication_id}
    assert_response :success
    assert File.exists? file
    get :published, {format: :pdf, id: @published.publication_id}
    assert_response :success
    # XLS
    file = Rails.root.join 'sheets', "#{@published.current_revision.reference}.xls"
    File.delete(file) rescue nil?
    get :published, {format: :xls, id: @published.publication_id}
    assert_response :success
    assert File.exists? file
    get :published, {format: :xls, id: @published.publication_id}
    assert_response :success
  end

  test "edit and update disbursement" do
    log_in :operator
    get :edit, id: @published.id
    assert_response :success
    post :update, id: @published.id
    assert_response :redirect
    log_out
  end

  test "access log" do
    log_in :operator
    get :access_log, id: @published.id
    assert_response :success
    log_out
  end

  test "print disbursement" do
    log_in :operator
    get :print, id: @published.id
    assert_response :success
    log_out
  end

  test "show disbursement" do
    log_in :operator
    get :show, id: @published.id
    assert_response :success
    log_out
  end
end
