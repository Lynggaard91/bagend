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

# Talos Image Factory Configuration
locals {
  talos_version      = "v1.12.0"
  talos_platform     = "nocloud"
  talos_architecture = "amd64"
  talos_extensions   = ["intel-ucode", "qemu-guest-agent", "iscsi-tools"]
}

data "talos_image_factory_extensions_versions" "this" {
  talos_version = local.talos_version
  filters = {
    names = local.talos_extensions
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = [
          for ext in data.talos_image_factory_extensions_versions.this.extensions_info : ext.name
        ]
      }
    }
  })
}

data "talos_image_factory_urls" "this" {
  talos_version = local.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = local.talos_platform
  architecture  = local.talos_architecture
}

locals {
  proxmox = {
    cluster_name = "bagend"
    endpoint     = "https://pve1.bagend.lynggaardjensen.com:8006/"
    insecure     = false
    username     = "root"
    api_token    = "root@pam!tf=315fa490-759e-489b-aa33-b80b2d99f440"
  }

  # Infrastructure (Proxmox VM) definitions
  proxmox_nodes = {
    controlplane-01 = {
      hostname      = "pve1"
      ip            = "192.168.1.15/24"
      gateway_ip    = "192.168.1.1"
      vm_id         = 201
      cpu           = 2
      ram_dedicated = 2048
      boot_disk = {
        size = 10
      }
      efi_disk_enabled = true
    }
  }

  # Talos-specific node configurations
  talos_nodes = {
    controlplane-01 = {
      ip           = "192.168.1.15"
      machine_type = "controlplane"
      config_patches = [
        file("${path.module}/talos/machine-config-patches/controlplane.yaml")
      ]
    }
  }
}

module "vms_talos" {
  source = "./proxmox_vm"

  nodes = local.proxmox_nodes

  boot_image = {
    url       = data.talos_image_factory_urls.this.urls.iso
    file_name = "talos-${local.talos_version}-${local.talos_platform}-${local.talos_architecture}.iso"
  }
}

module "talos_cluster" {
  source = "./talos"

  nodes = local.talos_nodes

  cluster = {
    name     = "bagend"
    endpoint = "192.168.1.15"

    config_patches = [
      templatefile("${path.module}/talos/machine-config-patches/base-cluster.yaml", {
        talos_imagefactory_image = data.talos_image_factory_urls.this.urls.installer
      })
    ]
  }

  talos_version      = local.talos_version
  kubernetes_version = "1.35.0"

  proxmox_vms = module.vms_talos.vms

  depends_on = [module.vms_talos]
}
