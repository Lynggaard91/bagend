locals {
  proxmox = {
    cluster_name = "bagend"
    endpoint     = "https://pve1.lynggaardjensen.com:8006/"
    insecure     = false
    username     = "root"
    api_token    = var.proxmox_api_token
  }

  talos_version      = "v1.14.1"
  talos_platform     = "nocloud"
  talos_architecture = "amd64"
  talos_extensions   = ["intel-ucode", "qemu-guest-agent", "iscsi-tools"]

  # Canonical node definitions — single source of truth for all modules
  nodes = {
    controlplane-01 = {
      # Proxmox VM fields
      hostname      = "pve3"
      ip            = "192.168.1.15/24"
      gateway_ip    = "192.168.1.1"
      vm_id         = 203
      cpu           = 4
      ram_dedicated = 2048
      boot_disk = {
        size = 10
      }
      efi_disk_enabled = true
      boot_image = {
        url       = data.talos_image_factory_urls.this.urls.iso
        file_name = "talos-${local.talos_version}-${local.talos_platform}-${local.talos_architecture}.iso"
      }
      agent = {
        enabled = true
        trim    = true
      }
      # Talos fields
      machine_type = "controlplane"
      config_patches = [
        file("${path.module}/talos/machine-config-patches/controlplane.yaml")
      ]
    }
    worker-01 = {
      # Proxmox VM fields
      hostname      = "pve1"
      ip            = "192.168.1.16/24"
      gateway_ip    = "192.168.1.1"
      vm_id         = 202
      cpu           = 2
      ram_dedicated = 1024
      boot_disk = {
        size = 10
      }
      efi_disk_enabled = true
      boot_image = {
        url       = data.talos_image_factory_urls.this.urls.iso
        file_name = "talos-${local.talos_version}-${local.talos_platform}-${local.talos_architecture}.iso"
      }
      agent = {
        enabled = true
        trim    = true
      }
      # Talos fields
      machine_type   = "worker"
      config_patches = []
    }
  }

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

module "vms_talos" {
  source = "./proxmox_vm"

  nodes = local.nodes
}

module "talos_cluster" {
  source = "./talos"

  depends_on = [module.vms_talos]

  nodes = local.nodes

  cluster = {
    name     = "bagend"
    endpoint = "kubernetes.lynggaardjensen.com"

    config_patches = [
      templatefile("${path.module}/talos/machine-config-patches/base-cluster.yaml", {
        talos_imagefactory_image = data.talos_image_factory_urls.this.urls.installer
      })
    ]
  }

  talos_version      = local.talos_version
  kubernetes_version = "1.37.0"

  proxmox_vms = module.vms_talos.vms
}
