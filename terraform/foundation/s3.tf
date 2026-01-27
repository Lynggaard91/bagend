module "terraform_state_backend" {
  source         = "git::https://github.com/cloudposse/terraform-aws-tfstate-backend?ref=v1.8.0"
  s3_bucket_name = "bagend-tfstate"

  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  terraform_state_file               = "bagend/foundation/terraform.tfstate"
  force_destroy                      = false
  enable_point_in_time_recovery      = false
  profile                            = "bagend"
}
