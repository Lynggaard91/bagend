terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.73"
    }
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
    }
  }
}
