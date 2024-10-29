terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    region         = "eu-west-1"
    bucket         = "bagend-tfstate"
    key            = "bagend/tfstate/terraform.tfstate"
    profile        = "bagend"
    encrypt        = "true"
    dynamodb_table = "lock"
  }
}
