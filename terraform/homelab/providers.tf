terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.82"
    }
    talos = {
      source  = "siderolabs/talos"
      version = ">=0.9"
    }
  }
  backend "s3" {
    region         = "eu-west-1"
    bucket         = "bagend-tfstate"
    key            = "bagend/homelab/terraform.tfstate"
    profile        = "bagend"
    encrypt        = "true"
    dynamodb_table = "lock"
  }
}

variable "proxmox_api_token" {
  description = "Proxmox API token, injected via TF_VAR_proxmox_api_token"
  type        = string
  sensitive   = true
}

provider "proxmox" {
  endpoint  = local.proxmox.endpoint
  api_token = local.proxmox.api_token

  ssh {
    agent       = true
    username    = local.proxmox.username
    private_key = file("~/.ssh/proxmox")
  }
}
