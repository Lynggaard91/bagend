locals {
  # Get node IPs (strip CIDR prefix if present)
  all_node_ips     = [for n in var.nodes : split("/", n.ip)[0]]
  controlplane_ips = [for n in var.nodes : split("/", n.ip)[0] if n.machine_type == "controlplane"]
  worker_ips       = [for n in var.nodes : split("/", n.ip)[0] if n.machine_type == "worker"]

  # First control plane IP for bootstrap
  bootstrap_node_ip = one(local.controlplane_ips)

  # Combine cluster-wide patches with per-node patches
  node_patches = {
    for name, node in var.nodes : name => concat(
      var.cluster.config_patches,
      node.config_patches
    )
  }
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = local.all_node_ips
  endpoints            = [var.cluster.endpoint]
}

data "talos_machine_configuration" "this" {
  for_each = var.nodes

  cluster_name       = var.cluster.name
  cluster_endpoint   = "https://${var.cluster.endpoint}:6443"
  talos_version      = var.talos_version
  machine_type       = each.value.machine_type
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  kubernetes_version = var.kubernetes_version

  config_patches = local.node_patches[each.key]

}

# Wait for machines to reboot and become ready after config apply
resource "time_sleep" "wait_for_machine_first_boot" {
  create_duration = "3m"
}

resource "talos_machine_configuration_apply" "this" {
  for_each = var.nodes

  node                        = split("/", each.value.ip)[0]
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration

  depends_on = [time_sleep.wait_for_machine_first_boot]
}

resource "talos_machine_bootstrap" "this" {
  node                 = var.cluster.endpoint
  client_configuration = talos_machine_secrets.this.client_configuration

  depends_on = [talos_machine_configuration_apply.this]
}

# Wait for cluster to stabilize after bootstrap
resource "time_sleep" "wait_for_cluster_ready" {
  create_duration = "2m"

  depends_on = [talos_machine_bootstrap.this]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.bootstrap_node_ip
  endpoint             = var.cluster.endpoint

  depends_on = [talos_machine_bootstrap.this]
}

resource "local_file" "kubeconfig" {
  content         = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename        = "${path.module}/kubeconfig"
  file_permission = "0600"
}

resource "local_file" "talosconfig" {
  content         = data.talos_client_configuration.this.talos_config
  filename        = "${path.module}/talosconfig"
  file_permission = "0600"
}

# Render Cilium helm values with dynamic cluster endpoint
resource "local_file" "cilium_helm_values" {
  content = templatefile("${path.cwd}/kubernetes/cilium/helm-values-template.yaml", {
    cluster_endpoint = var.cluster.endpoint
  })
  filename        = "${path.cwd}/kubernetes/cilium/helm-values.yaml"
  file_permission = "0644"
}
