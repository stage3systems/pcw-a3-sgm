CarrierWave.configure do |config|
  config.fog_credentials = {
    provider:              'AWS',
    aws_access_key_id:     Rails.application.config.x.s3["aws_access_key_id"],
    aws_secret_access_key: Rails.application.config.x.s3["aws_secret_access_key"],
    region:                Rails.application.config.x.s3["region"],
    use_iam_profile:       Rails.application.config.x.s3["use_iam_profile"]
  }
  if config.fog_credentials[:use_iam_profile]
    config.fog_credentials.delete(:aws_access_key_id)
    config.fog_credentials.delete(:aws_secret_access_key)
  end
  config.fog_directory  = Rails.application.config.x.s3["bucket"]
  config.fog_public     = false
end
