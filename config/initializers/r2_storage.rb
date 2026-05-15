require "aws-sdk-s3"

R2_BUCKET   = ENV.fetch("R2_BUCKET", "atreus-ventas")
R2_ENDPOINT = "https://#{ENV.fetch("R2_ACCOUNT_ID", "")}.r2.cloudflarestorage.com"
R2_PUBLIC_URL = ENV.fetch("R2_PUBLIC_URL", "https://pub-placeholder.r2.dev")

R2_CLIENT = if ENV["R2_ACCESS_KEY_ID"].present?
  Aws::S3::Client.new(
    access_key_id:     ENV.fetch("R2_ACCESS_KEY_ID"),
    secret_access_key: ENV.fetch("R2_SECRET_ACCESS_KEY"),
    endpoint:          R2_ENDPOINT,
    region:            "auto",
    force_path_style:  true,
    request_checksum_calculation:  "when_required",
    response_checksum_validation:  "when_required"
  )
else
  Rails.logger.warn "[R2] R2_ACCESS_KEY_ID not set — file uploads will be unavailable"
  nil
end

R2_PRESIGNER = R2_CLIENT ? Aws::S3::Presigner.new(client: R2_CLIENT) : nil
