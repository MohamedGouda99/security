output "service_uri" {
  description = "URL for the Cloud Run service."
  value       = google_cloud_run_service.service.status[0].url
}

output "neg_name" {
  description = "Serverless NEG for load balancing."
  value       = try(google_compute_region_network_endpoint_group.neg[0].name, null)
}
