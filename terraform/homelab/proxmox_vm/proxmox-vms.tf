resource "proxmox_virtual_environment_vm" "this" {
  for_each = var.nodes

  node_name = each.value.hostname

  name            = each.key
  description     = each.value.description
  tags            = each.value.tags
  on_boot         = true
  vm_id           = each.value.vm_id
  machine         = each.value.machine
  scsi_hardware   = each.value.scsi_hardware
  bios            = each.value.bios
  keyboard_layout = each.value.keyboard_layout

  agent {
    enabled = each.value.agent.enabled
    trim    = each.value.agent.trim
  }

  cpu {
    cores = each.value.cpu
    type  = each.value.cpu_type
  }

  memory {
    dedicated = each.value.ram_dedicated
  }

  dynamic "network_device" {
    for_each = each.value.network_devices
    content {
      bridge      = network_device.value.bridge
      firewall    = network_device.value.firewall
      mac_address = network_device.value.mac_address
      model       = network_device.value.model
      vlan_id     = network_device.value.vlan_id
    }
  }

  dynamic "disk" {
    for_each = [each.value.boot_disk]
    content {
      datastore_id = each.value.datastore_id
      interface    = disk.value.interface
      size         = disk.value.size
      file_format  = disk.value.file_format
      cache        = disk.value.cache
      discard      = disk.value.discard
      iothread     = disk.value.iothread
      replicate    = disk.value.replicate
      ssd          = disk.value.ssd
      file_id      = try(proxmox_virtual_environment_download_file.this[each.key].id, disk.value.import_from)
    }
  }

  dynamic "disk" {
    for_each = each.value.extra_disks
    content {
      datastore_id = each.value.datastore_id
      interface    = disk.value.interface
      size         = disk.value.size
      file_format  = disk.value.file_format
      cache        = disk.value.cache
      discard      = disk.value.discard
      iothread     = disk.value.iothread
      replicate    = disk.value.replicate
      ssd          = disk.value.ssd
      import_from  = disk.value.file
    }
  }

  dynamic "efi_disk" {
    for_each = each.value.efi_disk_enabled ? [1] : []
    content {
      datastore_id = each.value.datastore_id
    }
  }

  operating_system {
    type = each.value.operating_system.type
  }

  initialization {
    datastore_id = each.value.datastore_id
    interface    = "scsi1"
    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = each.value.gateway_ip
      }
    }
  }

  dynamic "hostpci" {
    for_each = each.value.igpu ? [1] : []
    content {
      device  = "hostpci0"
      mapping = "iGPU"
      pcie    = true
      rombar  = true
      xvga    = false
    }
  }
}

# Download boot image per VM
resource "proxmox_virtual_environment_download_file" "this" {
  for_each = var.boot_image != null ? var.nodes : {}

  node_name    = each.value.hostname
  content_type = "iso"
  datastore_id = each.value.datastore_id_images

  file_name = var.boot_image.file_name
  url       = var.boot_image.url
  overwrite = true
}
