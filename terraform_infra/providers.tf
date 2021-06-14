provider "aws" {
  # alias      = "local"
  access_key = "mock_access_key"
  region     = var.aws_region
  #   profile = var.profile
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_force_path_style         = true

  endpoints {
    s3         = var.host
    lambda     = var.host
    iam        = var.host
    apigateway = var.host
  }
}

provider "archive" {}