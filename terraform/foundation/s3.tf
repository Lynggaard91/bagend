module "terraform_state_backend" {
  source         = "cloudposse/tfstate-backend/aws"
  version        = "1.3.0"
  s3_bucket_name = "bagend-tfstate"

  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false
  enable_point_in_time_recovery      = false
}
