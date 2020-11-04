require 'aws-sdk-sns'
config = Rails.application.config.x.sns
credentials = Aws::InstanceProfileCredentials.new
Aws.config.update({
  region: "us-west-2",
  credentials: credentials
})




