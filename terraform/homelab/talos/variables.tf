variable "nodes" {
  description = "Map of Talos nodes to configure with machine type and optional config patches"
  type = map(object({
    ip             = string
    machine_type   = string # "controlplane" or "worker"
    config_patches = optional(list(string), [])
    install_disk   = optional(string, "/dev/sda")
    install_image  = optional(string)
  }))
}

variable "cluster" {
  description = "Talos cluster-level configuration"
  type = object({
    name           = string
    endpoint       = string
    config_patches = optional(list(string), [])
  })
}

variable "proxmox_vms" {
  description = "VM resources from proxmox module (for dependency tracking)"
  type        = any
  default     = {}
}

variable "talos_version" {
  description = "Talos Linux version"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}
