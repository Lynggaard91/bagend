terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.73"
    }
  }
  backend "s3" {
    region         = "eu-west-1"
    bucket         = "bagend-tfstate"
    key            = "bagend/aws/terraform.tfstate"
    profile        = "bagend"
    encrypt        = "true"
    dynamodb_table = "lock"
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "bagend"

  default_tags {
    tags = {
      env       = "bagend"
      terraform = "true"
    }
  }
}
