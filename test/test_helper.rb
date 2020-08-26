require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
SimpleCov.start
ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'

WebMock.disable_net_connect!(allow_localhost: true, allow: 'codeclimate.com')
Delayed::Worker.delay_jobs = false

if RUBY_VERSION>='2.6.0'
  if Rails.version < '5'
    class ActionController::TestResponse < ActionDispatch::TestResponse
      def recycle!
        # hack to avoid MonitorMixin double-initialize error:
        @mon_mutex_owner_object_id = nil
        @mon_mutex = nil
        initialize
      end
    end
  else
    puts "Monkeypatch for ActionController::TestResponse no longer needed"
  end
end


class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionController::TestCase

  setup do
    request.host = 'monson.test.host'
  end

  def log_in(user)
    u =  users(user)
    session[:token] = {
      "sub" => "auth0|#{u.rocket_id}",
      "exp" => (DateTime.now+1.day).to_i
    }
  end

  def log_out
    session[:token] = nil
  end
end

def aos_url(path)
  "https://test.agencyops.net/api/v1/#{path}"
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
      with(basic_auth: ['test', 'test']).
      to_return(aos_result(entity, result))
end

