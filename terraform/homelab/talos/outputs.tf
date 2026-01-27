output "kubeconfig" {
  description = "Kubernetes cluster kubeconfig"
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "talosconfig" {
  description = "Talos client configuration for talosctl"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "control_plane_ips" {
  description = "List of control plane node IP addresses"
  value       = local.controlplane_ips
}

output "worker_ips" {
  description = "List of worker node IP addresses"
  value       = local.worker_ips
}

# output "cluster_health" {
#   description = "Cluster health status"
#   value       = data.talos_cluster_health.after_config_apply
# }

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = "https://${var.cluster.endpoint}:6443"
}
