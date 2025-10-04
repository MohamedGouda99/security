output "network_id" {
  description = "Network ID provisioned for the environment."
  value       = module.networking.network_id
}

output "gke_cluster_name" {
  description = "GKE Autopilot cluster name."
  value       = module.gke.cluster_name
}

output "cloud_run_url" {
  description = "Deployed Cloud Run service URL."
  value       = module.cloudrun.service_uri
}

output "vertex_endpoint_id" {
  description = "Vertex AI endpoint resource name."
  value       = module.vertex.endpoint_id
}
