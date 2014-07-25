require 'test_helper'

class DisbursementsControllerTest < ActionController::TestCase
  setup do
    @published = disbursements(:published)
    @port = ports(:newcastle)
    @vessel = vessels(:vesselone)
    @cargo_type = cargo_types(:one)
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
                        appointmentId: 123,
                        vesselId: 1,
                        principalId: 1,
                        portId: 1,
                        nominationNumber: 'A'
                      }]
                    }
                  }.to_json, :headers => {})
    stub_request(:get, "https://test:test@test.agencyops.net/api/v1/appointment/123").
        to_return(:status => 200, :body => {
          data: {
            appointment: [{
              fileNumber: '123456789'
            }]
          }
        }.to_json, :headers => {})
    get :new, nomination_id: 123
    assert_response :success
    log_out
  end

  test "set status" do
    log_in :operator
    post :status, {id: @published.id, status: "close"}
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
    post :search, {format: :json, port_id: 1, cargo_type_id: @cargo_type.id}
    assert_response :success
    log_out
  end

  test "view published disbursements" do
    # unknown id should display page
    get :published, id: "321654987"
    assert_response :success
    ["inquiry", "draft", "initial", "close"].each do |s|
      [:generic, :generic_tax_exempt].each do |d|
        @da = disbursements(d)
        # set status
        log_in :operator
        post :status, {id: @da.id, status: s}
        assert_response :redirect
        log_out
        # Page
        get :published, id: @da.publication_id
        assert_response :success
        # PDF
        file = Rails.root.join 'pdfs', "#{@da.current_revision.reference}.pdf"
        File.delete(file) rescue nil?
        get :published, {format: :pdf, id: @da.publication_id}
        assert_response :success
        assert File.exists? file
        get :published, {format: :pdf, id: @da.publication_id}
        assert_response :success
        # XLS
        file = Rails.root.join 'sheets', "#{@da.current_revision.reference}.xls"
        File.delete(file) rescue nil?
        get :published, {format: :xls, id: @da.publication_id}
        assert_response :success
        assert File.exists? file
        get :published, {format: :xls, id: @da.publication_id}
        assert_response :success
      end
    end
  end

  test "edit and update disbursement" do
    log_in :operator
    get :edit, id: @published.id
    assert_response :success
    post :update, id: @published.id, disbursement_revision: {tugs_in: 2}
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

  test "show revisions" do
    log_in :admin
    get :revisions, id: @published.id
    assert_response :success
    log_out
  end

  test "disbursement lifecycle" do
    log_in :office_operator
    stub_request(:get, "https://test:test@test.agencyops.net/api/v1/disbursement?nominationId=321").
        to_return(:status => 200, :body => {
          data: {
            count: 0,
            page: 0,
            disbursement: []
          }
        }.to_json, :headers => {})
    post :create, disbursement: {
      type_cd: 0,
      port_id: @port.id,
      company_id: @company.id,
      tbn: false,
      vessel_id: @vessel.id,
      appointment_id: 321,
      nomination_id: 321
    }
    d = assigns(:disbursement)
    post :update, id: d.id, disbursement_revision: {
      cargo_qty: 10000,
      loadtime: 2.0,
      tax_exempt: false,
      tugs_in: 2,
      tugs_out: 2
    }
    assert_redirected_to disbursements_path
    post :update, id: d.id, disbursement_revision: {
      cargo_qty: 20000,
      loadtime: 2.0,
      tax_exempt: false,
      tugs_in: 2,
      tugs_out: 2
    }
    assert_redirected_to disbursements_path
    get :published, id: @published.publication_id
    assert_response :success
    get :published, id: @published.publication_id, revision_number: 1
    assert_response :success
    delete :destroy, id: d.id
    log_out
  end

end
