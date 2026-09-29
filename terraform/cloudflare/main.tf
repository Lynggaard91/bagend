terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.73"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    region         = "eu-west-1"
    bucket         = "bagend-tfstate"
    key            = "bagend/cloudflare/terraform.tfstate"
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

data "aws_ssm_parameter" "cloudflare_api_token" {
  name = "/bagend/cloudflare/api_token"
}

provider "cloudflare" {
  api_token = data.aws_ssm_parameter.cloudflare_api_token.value
}
