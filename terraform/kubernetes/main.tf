terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.8"
    }
  }
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "cjlynge"

    workspaces {
      name = "cjlynge_kubernetes"
    }
  }
}

data "terraform_remote_state" "dns" {
  backend = "remote"

  config = {
    organization = "cjlynge"
    workspaces = {
      name = "cjlynge_dns"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "bagend"
}
