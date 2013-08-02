class AosUser < ActiveResource::Base
  self.site = "#{ProformaDA::Application.config.aos_api_url}/users"
  self.user = ProformaDA::Application.config.aos_api_user
  self.password = ProformaDA::Application.config.aos_api_password
end
