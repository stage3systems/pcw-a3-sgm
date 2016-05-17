CarrierWave.configure do |config|
  config.fog_credentials = {
    provider:              'AWS',
    aws_access_key_id:     Rails.application.config.x.tenant["s3"]["aws_access_key_id"],
    aws_secret_access_key: Rails.application.config.x.tenant["s3"]["aws_secret_access_key"],
    region:                Rails.application.config.x.tenant["s3"]["region"],
    use_iam_profile:       Rails.application.config.x.tenant["s3"]["use_iam_profile"]
  }
  config.fog_directory  = Rails.application.config.x.tenant["s3"]["bucket"]
  config.fog_public     = false
end
