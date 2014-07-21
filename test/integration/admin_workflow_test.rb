require 'test_helper'

class AdminWorkflowTest < ActionDispatch::IntegrationTest
  test "admin workflow" do
    https!
    get "/users/auth/saml"
    assert_response :success
    post_via_redirect "/users/auth/saml",
                      user: {
                        login: 'admin', password: 'test'
                      }
    assert_equal '/', path
    assert_equal 'Signed in successfully.', flash[:notice]
    # create new disbursement
    get "/disbursements/new"
    assert_response :success
    # log out
    delete_via_redirect '/sign_out'
    assert_equal '/users/auth/saml', path
  end
end
