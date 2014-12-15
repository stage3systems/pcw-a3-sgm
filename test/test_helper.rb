require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
SimpleCov.start
ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'

WebMock.disable_net_connect!(allow_localhost: true, allow: 'codeclimate.com')
Delayed::Worker.delay_jobs = false

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionController::TestCase
  include Devise::TestHelpers

  def log_in(user)
    @request.env["devise.mapping"] = Devise.mappings[user]
    @user = users(user)
    sign_in @user
  end
  def log_out
    sign_out @user
  end
end

def aos_url(path)
  "https://test:test@test.agencyops.net/api/v1/#{path}"
end
def aos_result(entity, value)
  {
    :status => 200, :body => {
      data: {
        count: value.length,
        page: 0,
        entity => value
      }
    }.to_json,
    :headers => {}
  }
end
def aos_stub(method, url, entity, result)
  stub_request(method, aos_url(url)).
      to_return(aos_result(entity, result))
end

