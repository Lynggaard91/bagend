resource "kubernetes_secret" "cjlyngeservice_iam_token" {
  metadata {
    name = "bagend-externaldns"
  }

  data = {
    AWS_ACCESS_KEY_ID     = data.terraform_remote_state.dns.outputs.cjlyngeservice_key_id
    AWS_SECRET_ACCESS_KEY = data.terraform_remote_state.dns.outputs.cjlyngeservice_secret
  }

  type = "Opaque"
}
