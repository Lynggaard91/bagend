terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.2"
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
      pattern   = "tfstate"
    }
  }
}
