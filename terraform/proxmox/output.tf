output "proxmox_user_key_id" {
  value = module.user_proxmox.iam_access_key_id
}

output "proxmox_user_key_secret" {
  value     = module.user_proxmox.iam_access_key_secret
  sensitive = true
}
