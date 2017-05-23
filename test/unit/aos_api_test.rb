require 'test_helper'

class AosApiTest < ActiveSupport::TestCase
  def setup
    t = Tenant.new({
      name: 'test',
      aos_api_user: 'test',
      aos_api_password: 'test',
      aos_api_url: 'https://test.agencyops.net/api'
    })
    @api = AosApi.new(t)
  end

  test "save" do
    stub_request(:post, "https://test.agencyops.net/api/v1/save/dummy").
        with(:body => "{\"name\":\"dummy\",\"foo\":\"bar\"}",
                    :headers => {'Content-Type'=>'application/json'},
                    :basic_auth => ['test', 'test']).
          to_return(:status => 200, :body => {
            status: 'success',
            data: {dummy: [{id: 1}]}
          }.to_json, :headers => {})
    @api.save('dummy', {name: 'dummy', foo: 'bar'})
    stub_request(:post, "https://test.agencyops.net/api/v1/save/dummy").
        with(:body => "{\"name\":\"dummy\",\"foo\":\"bar\"}",
                    :headers => {'Content-Type'=>'application/json'},
                    :basic_auth => ['test', 'test']).
          to_return(:status => 200, :body => {
            data: {dummy: [{id: 1}]}
          }.to_json, :headers => {})
    @api.save('dummy', {name: 'dummy', foo: 'bar'})
  end

  test "delete" do
    stub_request(:get, "https://test.agencyops.net/api/v1/delete/dummy/1").
        with(basic_auth: ['test', 'test']).
        to_return(:status => 200, :body => "", :headers => {})
    @api.delete('dummy', 1)
  end

  test "query" do
    stub_request(:get, "https://test.agencyops.net/api/v1/dummy?fooId=1").
        with(basic_auth: ['test', 'test']).
        to_return(:status => 200, :body => "", :headers => {})
    @api.query('dummy', {fooId: 1})
  end

  test "first" do
    stub_request(:get, "https://test.agencyops.net/api/v1/dummy").
        with(basic_auth: ['test', 'test']).
        to_return(:status => 200, :body => {
      data: {dummy: []}
    }.to_json, :headers => {})
    @api.first('dummy')
  end

  test "each" do
    stub_request(:get, "https://test.agencyops.net/api/v1/dummy").
        with(basic_auth: ['test', 'test']).
        to_return(:status => 200, :body => {
          data: {
            count: 2,
            page: 0,
            dummy: [{id: 1, foo: 'bar'}, {id: 2, foo: 'bar'}]
          }
        }.to_json, :headers => {})
    @api.each('dummy') do |d|
      assert d['foo'] == 'bar'
    end
  end

  test "users" do
    stub_request(:get, "https://test.agencyops.net/api/v1/person?companyId=1").
        with(basic_auth: ['test', 'test']).
        to_return(:status => 200, :body => {
          data: {
            count: 1,
            page: 0,
            person: [{id: 1, name: 'foo'}]
          }
        }.to_json, :headers => {})
    stub_request(:get, "https://test.agencyops.net/api/v1/person?companyId=2").
        with(basic_auth: ['test', 'test']).
        to_return(:status => 200, :body => {
          data: {
            count: 1,
            page: 0,
            person: [{id: 2, name: 'bar'}]
          }
        }.to_json, :headers => {})
    users = @api.users
    assert users.count == 2
    assert users[0]['name'] == 'foo'
    assert users[1]['name'] == 'bar'
  end

  test "offices" do
    stub_request(:get, "https://test.agencyops.net/api/v1/office?agencyCompany=1").
        with(basic_auth: ['test', 'test']).
        to_return(:status => 200, :body => {
          data: {
            count: 1,
            page: 0,
            office: [{id: 1, name: 'test'}]
          }
        }.to_json, :headers => {})
    stub_request(:get, "https://test.agencyops.net/api/v1/emailAddress?officeId=1&prime=1").
        with(basic_auth: ['test', 'test']).
        to_return(:status => 200, :body => {
          data: {
            count: 1,
            page: 0,
            emailAddress: [{id: 1, address: 'a@a.net'}]
          }
        }.to_json, :headers => {})
    @api.offices
  end

  test "companies" do
    stub_request(:get, "https://test.agencyops.net/api/v1/company").
        with(basic_auth: ['test', 'test']).
        to_return(:status => 200, :body => {
          data: {
            count: 1,
            page: 0,
            company: [{id: 1, name: 'c'}]
          }
        }.to_json, :headers => {})
    stub_request(:get, "https://test.agencyops.net/api/v1/emailAddress?companyId=1&prime=1").
        with(basic_auth: ['test', 'test']).
        to_return(:status => 200, :body => {
          data: {
            count: 1,
            page: 0,
            emailAddress: [{id: 1, address: 'a@a.net'}]
          }
        }.to_json, :headers => {})
    @api.companies
  end
end
