terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.2"
    }
  }
  backend "s3" {
    region         = "eu-west-1"
    bucket         = "bagend-tfstate"
    key            = "bagend/dns/terraform.tfstate"
    profile        = "bagend"
    encrypt        = "true"
    dynamodb_table = "lock"
  }
}

provider "aws" {
  region                   = "eu-west-1"
  shared_credentials_files = ["~/.aws/config"]
  profile                  = "bagend"

  default_tags {
    tags = {
      env       = "bagend"
      terraform = "true"
      pattern   = "dns"
    }
  }
}
