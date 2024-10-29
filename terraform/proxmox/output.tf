output "cjlyngeservice_key_id" {
  value = module.user_cjlyngeservice.iam_access_key_id
}

output "cjlyngeservice_secret" {
  value     = module.user_cjlyngeservice.iam_access_key_secret
  sensitive = true
}
