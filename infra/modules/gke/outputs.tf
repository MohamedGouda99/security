output "cluster_name" {
  description = "Name of the Autopilot cluster."
  value       = google_container_cluster.autopilot.name
}

output "endpoint" {
  description = "Endpoint for the GKE control plane."
  value       = google_container_cluster.autopilot.endpoint
}

output "ca_certificate" {
  description = "Public CA certificate for the cluster."
  value       = google_container_cluster.autopilot.master_auth[0].cluster_ca_certificate
}

output "workload_identity_pool" {
  description = "Workload identity pool configured for the cluster."
  value       = google_container_cluster.autopilot.workload_identity_config[0].workload_pool
}
