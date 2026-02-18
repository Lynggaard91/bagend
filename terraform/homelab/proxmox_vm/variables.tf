variable "nodes" {
  description = "Proxmox configuration for cluster nodes"
  type = map(object({
    ip                  = string
    gateway_ip          = string
    hostname            = string
    vm_id               = number
    cpu                 = number
    ram_dedicated       = number
    igpu                = optional(bool, false)
    description         = optional(string, "")
    tags                = optional(list(string), [])
    datastore_id        = optional(string, "local-lvm")
    datastore_id_images = optional(string, "local")
    bios                = optional(string, "ovmf")
    machine             = optional(string, "q35")
    scsi_hardware       = optional(string, "virtio-scsi-single")
    keyboard_layout     = optional(string, "da")
    cpu_type            = optional(string, "x86-64-v2")
    efi_disk_enabled    = optional(bool, false)

    agent = optional(object({
      enabled = bool
      trim    = bool
      }), {
      enabled = true
      trim    = true
    })

    operating_system = optional(object({
      type = string
      }), {
      type = "l26"
    })

    # See https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm
    # For specifics regarding network devices and disks.
    network_devices = optional(any, [
      { bridge = "vmbr0", firewall = null, mac_address = null, model = null, rate_limit = null, vlan_id = null }
    ])

    boot_disk = object({
      import_from = optional(string, "")
      interface   = optional(string, "scsi0")
      size        = optional(number, 8)
      cache       = optional(string, "none")
      discard     = optional(string, "ignore")
      file_format = optional(string, "raw")
      iothread    = optional(bool, false)
      replicate   = optional(bool, true)
      ssd         = optional(bool, true)
    })

    extra_disks = optional(any, [])

    boot_image = optional(object({
      url       = string
      file_name = string
    }))

    # Talos fields (passed through, not used by this module)
    machine_type   = optional(string)
    config_patches = optional(list(string), [])

  }))
}
