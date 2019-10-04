require 'test_helper'

class JsonrpcControllerTest < ActionController::TestCase

  test "invalid request" do
    get :index, format: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body['error']['code'] == -32600
  end

  test "invalid method" do
    post :index, {format: :json, id: 1, method: 'noop', "params" => ['none']}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['error']['code'] == -32601
  end

  test "invalid token" do
    post :index, {format: :json, id: 1, method: 'sync', "params" => ['none']}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['error']['code'] == -32000
  end

  test "sync invalid action" do
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => ['changeme', "NOOP", "none", nil]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['error']['code'] == -32000
  end

  test "sync unsupported entity" do
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => ['changeme', "DELETE", "none", nil]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['error']['code'] == -32001
  end

  test "can create, modify and delete users" do
    @tenant = tenants(:one)
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                      'changeme',
                      "CREATE",
                      "person",
                      {
                          id: 123,
                          loginName: "jsmith",
                          firstName: "John",
                          lastName: "Smith",
                          rocketId: 321
                      }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "ok", body['result']
    assert @tenant.users.find_by(remote_id: 123)
    assert @tenant.users.find_by(rocket_id: 2)
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                      'changeme',
                      "MODIFY",
                      "person",
                      {
                          id: 123,
                          loginName: "jsmith",
                          firstName: "Jeremy",
                          password: "$2a$14$AOXNCxxw6iLJw9Xwe1Bn9OjsWhRSXL5bi9Bk408ErsceSRgDVyZ7W",
                          lastName: "Smith"
                      }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "ok", body['result']
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                      'changeme',
                      "MODIFY",
                      "person",
                      {
                          id: 1234,
                          loginName: "jsmith",
                          firstName: "Jeremy",
                          password: "$2a$14$AOXNCxxw6iLJw9Xwe1Bn9OjsWhRSXL5bi9Bk408ErsceSRgDVyZ7W",
                          lastName: "Smith"
                      }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['error']['code'] == -32002
    assert User.find_by(remote_id: 123).first_name == 'Jeremy'
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                      'changeme',
                      "DELETE",
                      "person",
                      {
                          id: 123,
                      }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    assert User.find_by(remote_id: 123).nil?
  end


  test "can create, modify and delete cargo_types" do
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "CREATE",
                    "cargoType",
                    {
                      id: 123,
                      type: 't',
                      subtype: 'st',
                      subsubtype: 'sst',
                      subsubsubtype: 'ssst'
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    assert CargoType.find_by(remote_id: 123)
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "MODIFY",
                    "cargoType",
                    {
                      id: 123,
                      type: 't2',
                      subtype: 'st',
                      subsubtype: 'sst',
                      subsubsubtype: 'ssst'
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    assert CargoType.find_by(remote_id: 123).maintype = 't2'
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "DELETE",
                    "cargoType",
                    {
                      id: 123,
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    assert CargoType.find_by(remote_id: 123).nil?
  end

  test "companies and emailAddresses" do
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "CREATE",
                    "company",
                    {
                      id: 123,
                      name: 'Company One'
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    company = Company.find_by(remote_id: 123)
    assert company.name == 'Company One'
    assert company.email.nil?
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "CREATE",
                    "emailAddress",
                    {
                      id: 123,
                      companyId: 123,
                      prime: 1,
                      address: 'info@company.one'
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    assert Company.find_by(remote_id: 123).email == 'info@company.one'
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "MODIFY",
                    "emailAddress",
                    {
                      id: 123,
                      companyId: 123,
                      prime: 1,
                      address: 'contact@company.one'
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    assert Company.find_by(remote_id: 123).email == 'contact@company.one'
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "DELETE",
                    "emailAddress",
                    {
                      id: 123,
                      companyId: 123,
                      prime: 1,
                      address: 'contact@company.one'
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    assert Company.find_by(remote_id: 123).email.nil?
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "DELETE",
                    "company",
                    {
                      id: 123
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    assert Company.find_by(remote_id: 123).nil?
  end
  test "offices and email addresses" do
    @tenant = tenants(:one)
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "CREATE",
                    "office",
                    {
                      id: 123,
                      name: 'Office One',
                      address: "123\r\nStreet\r\nState"
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    office = @tenant.offices.find_by(remote_id: 123)
    assert office.name == 'Office One'
    assert office.address_1 == '123'
    assert office.address_2 == 'Street'
    assert office.address_3 == 'State'
    assert office.email.nil?
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "CREATE",
                    "emailAddress",
                    {
                      id: 123,
                      officeId: 123,
                      prime: 1,
                      address: 'info@company.one'
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "ok", body['result']
    assert @tenant.offices.find_by(remote_id: 123).email == 'info@company.one'
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "MODIFY",
                    "emailAddress",
                    {
                      id: 123,
                      officeId: 123,
                      prime: 1,
                      address: 'contact@company.one'
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    assert Office.find_by(remote_id: 123).email == 'contact@company.one'
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "DELETE",
                    "emailAddress",
                    {
                      id: 123,
                      officeId: 123,
                      prime: 1,
                      address: 'contact@company.one'
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    assert Office.find_by(remote_id: 123).email.nil?
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "DELETE",
                    "office",
                    {
                      id: 123
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    assert Office.find_by(remote_id: 123).nil?
  end

  test "MODIFY creates vessel workaround" do
    aos_stub(:get, "vesselType/1", :vesselType, [{
      type: "maintype",
      subtype: "subtype"
    }])
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "MODIFY",
                    "vessel",
                    {
                      id: 1234,
                      name: 'bar',
                      loa: 100,
                      vesselTypeId: 1,
                      intlNetRegisteredTonnage: 10000,
                      intlGrossRegisteredTonnage: 20000,
                      fullSummerDeadweight: 30000
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    v = Vessel.find_by(remote_id: 1234)
    assert v.name == 'bar'
    assert v.loa == 100
    assert v.nrt == 10000
    assert v.grt == 20000
    assert v.dwt == 30000
    assert_equal "maintype", v.maintype
    assert_equal "subtype", v.subtype
    v.destroy
  end

  test "activity code lifecycle" do
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    'CREATE',
                    'activityCode',
                    {
                      id: 123,
                      name: 'Test code',
                      code: 'CODE'
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    c = ActivityCode.find_by(remote_id: 123)
    assert c.name == 'Test code'
    assert c.code == 'CODE'
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "MODIFY",
                    "activityCode",
                    {
                      id: 123,
                      name: 'Updated test code',
                      code: 'CODE'
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    c = ActivityCode.find_by(remote_id: 123)
    assert c.name == 'Updated test code'
    assert c.code == 'CODE'
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "DELETE",
                    "activityCode",
                    {
                      id: 123
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    assert ActivityCode.find_by(remote_id: 123).nil?
  end

  test "vessel lifecycle" do
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "CREATE",
                    "vessel",
                    {
                      id: 123,
                      name: 'foo',
                      loa: 100,
                      intlNetRegisteredTonnage: 10000,
                      intlGrossRegisteredTonnage: 20000,
                      fullSummerDeadweight: 30000
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    v = Vessel.find_by(remote_id: 123)
    assert v.name == 'foo'
    assert v.loa == 100
    assert v.nrt == 10000
    assert v.grt == 20000
    assert v.dwt == 30000
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "MODIFY",
                    "vessel",
                    {
                      id: 123,
                      name: 'bar',
                      loa: 110
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    v = Vessel.find_by(remote_id: 123)
    assert v.name == 'bar'
    assert v.loa == 110
    post :index, {format: :json, id: 1, method: 'sync',
                  "params" => [
                    'changeme',
                    "DELETE",
                    "vessel",
                    {
                      id: 123
                    }
                  ]}
    assert_response :success
    body = JSON.parse(response.body)
    assert body['result'] == "ok"
    assert Vessel.find_by(remote_id: 123).nil?
  end
end
