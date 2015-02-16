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
    assert_not_nil assigns(:disbursements_grid)
    log_out
    log_in :operator
    get :index
    assert_response :success
    assert_not_nil assigns(:disbursements_grid)
    log_out
  end

  test "new disbursement" do
    log_in :admin
    stub_no_agency_fee
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
    aos_stub(:get, "nomination/123",
             :nomination, [{
                appointmentId: 123,
                vesselId: 1,
                principalId: 1,
                portId: 1,
                nominationNumber: 'A'
              }])
    aos_stub(:get, "appointment/123", :appointment, [{fileNumber: '123456789'}])
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
        @da.reload
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
    stub_no_agency_fee
    get :edit, id: @published.id
    assert_response :success
    post :update, id: @published.id,
                  disbursement: {status_cd: 3},
                  disbursement_revision: {tugs_in: 2}
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


  def stub_no_disbursement
    stub_request(:get, "https://test:test@test.agencyops.net/api/v1/disbursement?nominationId=321").
        to_return(aos_result(:disbursement, []))
  end

  def agency_fee_url(date=Date.today,port_id=654)
    "agencyFee?companyId=321&dateEffectiveEnd=#{date}&"+
    "dateExpiresStart=#{date}&portId=#{port_id}"
  end

  def stub_no_agency_fee
    aos_stub(:get, agency_fee_url, :agencyFee, [])
  end

  test "disbursement lifecycle" do
    log_in :office_operator
    stub = stub_no_disbursement
    stub_no_agency_fee
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
    # update some values
    post :update, id: d.id, disbursement_revision: {
      cargo_qty: 20000,
      loadtime: 2.0,
      tax_exempt: true,
      tugs_in: 2,
      tugs_out: 2
    }
    assert_redirected_to disbursements_path
    # add disabled extra field
    reference = d.current_revision.reference.sub('REV. 1', 'REV. 3')
    stub_request(:post, "https://test:test@test.agencyops.net/api/v1/save/disbursement").
        with(:body => "{\"appointmentId\":321,\"nominationId\":321,\"payeeId\":321,\"creatorId\":987,\"estimatePdfUuid\":\"#{d.publication_id}\",\"status\":\"DRAFT\",\"modifierId\":987,\"grossAmount\":\"1100.00\",\"netAmount\":\"1000.00\",\"estimateId\":#{d.id},\"description\":\"New Item\",\"code\":\"EXTRAITEM123456\",\"reference\":\"#{reference}\",\"sort\":0,\"taxApplies\":false,\"comment\":\"Comment\",\"disabled\":true}",
                    :headers => {'Content-Type'=>'application/json'}).
          to_return(aos_result(:disbursement, [{id: 1}]))
    post :update, id: d.id,
      disbursement_revision: {
        cargo_qty: 20000,
        loadtime: 2.0,
        tax_exempt: true,
        tugs_in: 2,
        tugs_out: 2
      },
      value_EXTRAITEM123456: 0.0,
      overriden_EXTRAITEM123456: 1000.0,
      description_EXTRAITEM123456: "New Item",
      code_EXTRAITEM123456: "{taxApplies: true}",
      comment_EXTRAITEM123456: "Comment",
      disabled_EXTRAITEM123456: "1"
    assert_redirected_to disbursements_path
    # enable extra field
    reference = reference.sub('REV. 3', 'REV. 4')
    stub_request(:post, "https://test:test@test.agencyops.net/api/v1/save/disbursement").
        with(:body => "{\"appointmentId\":321,\"nominationId\":321,\"payeeId\":321,\"creatorId\":987,\"estimatePdfUuid\":\"#{d.publication_id}\",\"status\":\"DRAFT\",\"modifierId\":987,\"grossAmount\":\"1100.00\",\"netAmount\":\"1000.00\",\"estimateId\":#{d.id},\"description\":\"New Item\",\"code\":\"EXTRAITEM123456\",\"reference\":\"#{reference}\",\"sort\":0,\"taxApplies\":false,\"comment\":\"Comment\",\"disabled\":false}",
                    :headers => {'Content-Type'=>'application/json'}).
          to_return(aos_result(:disbursement, [{id: 1}]))
    post :update, id: d.id,
      disbursement_revision: {
        cargo_qty: 20000,
        loadtime: 2.0,
        tax_exempt: true,
        tugs_in: 2,
        tugs_out: 2
      },
      value_EXTRAITEM123456: 0.0,
      overriden_EXTRAITEM123456: 1000.0,
      description_EXTRAITEM123456: "New Item",
      code_EXTRAITEM123456: "{taxApplies: true}",
      comment_EXTRAITEM123456: "Comment",
      disabled_EXTRAITEM123456: "0"
    assert_redirected_to disbursements_path
    # remove extra field
    remove_request_stub stub
    stub = stub_request(:get, "https://test:test@test.agencyops.net/api/v1/disbursement?nominationId=321").
        to_return(aos_result(:disbursement, [{id: 1, code: "EXTRAITEM123456"}]))

    stub_request(:get, "https://test:test@test.agencyops.net/api/v1/delete/disbursement/1").
        to_return(:status => 200, :body => "", :headers => {})
    post :update, id: d.id,
      disbursement_revision: {
        cargo_qty: 20000,
        loadtime: 2.0,
        tax_exempt: true,
        tugs_in: 2,
        tugs_out: 2
      }
    assert_redirected_to disbursements_path
    # check view
    get :published, id: d.publication_id
    assert_response :success
    get :published, id: d.publication_id, revision_number: 1
    assert_response :success
    delete :destroy, id: d.id
    log_out
  end

  test "disbursement agency fee lifecycle" do
    log_in :office_operator
    stub_no_disbursement
    # agency fees are crystalized from revision 0
    aos_stub(:get, agency_fee_url(Date.today.to_s, @port.remote_id), :agencyFee, [
      {id: 1,
       amount: "2000.0",
       title: "First fee",
       description: "Agency Fee",
       portId: @port.remote_id
      }
    ])
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
    get :edit, id: d.id
    assert_response :success
    dr = assigns(:revision)
    assert_not_nil dr
    assert_equal 0, dr.number
    assert_equal ['AGENCY-FEE-1'], dr.fields.keys
    reference = dr.reference.sub('REV. 0', 'REV. 1')
    stub_request(:post,
                 "https://test:test@test.agencyops.net/api/v1/save/disbursement").
        with(:body => "{\"appointmentId\":321,\"nominationId\":321,\"payeeId\":321,\"creatorId\":987,\"estimatePdfUuid\":\"#{d.publication_id}\",\"status\":\"DRAFT\",\"modifierId\":987,\"grossAmount\":\"2200.00\",\"netAmount\":\"2000.00\",\"estimateId\":#{d.id},\"description\":\"First fee\",\"code\":\"AGENCY-FEE-1\",\"reference\":\"#{reference}\",\"sort\":0,\"taxApplies\":true,\"comment\":null,\"disabled\":false}",
             :headers => {'Content-Type'=>'application/json'}).
          to_return(aos_result(:disbursement, [{id: 1}]))
    post :update, id: d.id,
                  disbursement: {},
                  disbursement_revision: {eta: "2015-01-12"}
    assert_redirected_to disbursements_path
    # edit again
    get :edit, id: d.id
    assert_response :success
    dr = assigns(:revision)
    assert_not_nil dr
    assert_equal 1, dr.number
    assert_equal ['AGENCY-FEE-1'], dr.fields.keys
    assert_equal "2200.0", dr.amount.to_s
    # override fee
    reference = dr.reference.sub('REV. 1', 'REV. 2')
    stub_request(:post,
                 "https://test:test@test.agencyops.net/api/v1/save/disbursement").
        with(:body => "{\"appointmentId\":321,\"nominationId\":321,\"payeeId\":321,\"creatorId\":987,\"estimatePdfUuid\":\"#{d.publication_id}\",\"status\":\"DRAFT\",\"modifierId\":987,\"grossAmount\":\"3300.00\",\"netAmount\":\"3000.00\",\"estimateId\":#{d.id},\"description\":\"First fee\",\"code\":\"AGENCY-FEE-1\",\"reference\":\"#{reference}\",\"sort\":0,\"taxApplies\":true,\"comment\":null,\"disabled\":false}",
             :headers => {'Content-Type'=>'application/json'}).
          to_return(aos_result(:disbursement, [{id: 1}]))
    post :update, id: d.id,
                  disbursement: {},
                  disbursement_revision: {eta: "2015-01-12"},
                  'overriden_AGENCY-FEE-1': "3000"
    assert_redirected_to disbursements_path
    # edit again
    get :edit, id: d.id
    assert_response :success
    dr = assigns(:revision)
    assert_not_nil dr
    assert_equal 2, dr.number
    assert_equal "3300.0", dr.amount.to_s
    assert_equal ['AGENCY-FEE-1'], dr.fields.keys
    # disable fee
    reference = dr.reference.sub('REV. 2', 'REV. 3')
    stub_request(:post,
                 "https://test:test@test.agencyops.net/api/v1/save/disbursement").
        with(:body => "{\"appointmentId\":321,\"nominationId\":321,\"payeeId\":321,\"creatorId\":987,\"estimatePdfUuid\":\"#{d.publication_id}\",\"status\":\"DRAFT\",\"modifierId\":987,\"grossAmount\":\"3300.00\",\"netAmount\":\"3000.00\",\"estimateId\":#{d.id},\"description\":\"First fee\",\"code\":\"AGENCY-FEE-1\",\"reference\":\"#{reference}\",\"sort\":0,\"taxApplies\":true,\"comment\":null,\"disabled\":true}",
             :headers => {'Content-Type'=>'application/json'}).
          to_return(aos_result(:disbursement, [{id: 1}]))
    post :update, id: d.id,
                  disbursement: {},
                  disbursement_revision: {eta: "2015-01-12"},
                  'overriden_AGENCY-FEE-1': "3000",
                  'disabled_AGENCY-FEE-1': "1"
    assert_redirected_to disbursements_path
    # edit again
    get :edit, id: d.id
    assert_response :success
    dr = assigns(:revision)
    assert_not_nil dr
    assert_equal 3, dr.number
    assert_equal "0.0", dr.amount.to_s
    assert_equal ['AGENCY-FEE-1'], dr.fields.keys

    log_out
  end
end
