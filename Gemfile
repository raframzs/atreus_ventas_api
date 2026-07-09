source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# Auth
gem "bcrypt", "~> 3.1"
gem "jwt", "~> 3.2"

# API
gem "rack-cors"
gem "rack-attack"

# Cloudflare R2 (S3-compatible)
gem "aws-sdk-s3", require: false

# Cache
gem "redis", "~> 5.0"

# Background jobs & cache (DB-backed)
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Excel export
gem "caxlsx"
gem "mini_magick"

# Utilities
gem "dotenv-rails", groups: [:development, :test]
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Deploy
gem "kamal", require: false
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

gem "image_processing", "~> 1.2"
