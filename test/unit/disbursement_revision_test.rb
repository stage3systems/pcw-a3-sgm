require 'test_helper'

class DisbursementRevisionTest < ActiveSupport::TestCase
  test "previous and next" do
    r = disbursement_revisions(:revisiontwo)
    assert r.next.nil?
    assert r.previous.nil?
  end

  test "sync with aos" do
    r = disbursement_revisions(:revisiontwo)
    r.disbursement.nomination_id = 1
    stub_request(:get, "https://test:test@test.agencyops.net/api/v1/disbursement?nominationId=1").
        to_return(:status => 200, :body => {
          data: {
            count: 2,
            page: 0,
            disbursement: [{id: 1, code: 'MNL'}, {id: 2, code: 'bar'}]
          }
        }.to_json, :headers => {})
    stub_request(:post, "https://test:test@test.agencyops.net/api/v1/save/disbursement").
        with(:body => "{\"id\":1,\"code\":\"MNL\",\"appointmentId\":null,\"nominationId\":1,\"payeeId\":null,\"creatorId\":1,\"modifierId\":1,\"grossAmount\":\"1100.0\",\"netAmount\":\"1000.0\",\"estimateId\":675045400,\"estimatePdfUuid\":\"id2\",\"description\":\"Marine Levy\",\"status\":\"INITIAL\",\"reference\":\"reference2\",\"sort\":1}",
                    :headers => {'Content-Type'=>'application/json'}).
          to_return(:status => 200, :body => {
            status: 'success',
            data: {
              disbursement: [{id: 1}]
            }
          }.to_json, :headers => {})
    stub_request(:get, "https://test:test@test.agencyops.net/api/v1/delete/disbursement/2").
        to_return(:status => 200, :body => "", :headers => {})
    r.sync_with_aos
  end
end
