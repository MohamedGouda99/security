output "cicd_service_account_email" {
  description = "Email address of the CI/CD service account."
  value       = google_service_account.cicd.email
}

output "app_service_account_email" {
  description = "Email address of the runtime service account."
  value       = google_service_account.app.email
}

output "vertex_service_account_email" {
  description = "Email address of the Vertex pipelines service account."
  value       = google_service_account.vertex.email
}

output "workload_identity_pool_name" {
  description = "Fully qualified name of the workload identity pool."
  value       = google_iam_workload_identity_pool.github.name
}

output "workload_identity_provider_name" {
  description = "Fully qualified name of the workload identity provider."
  value       = google_iam_workload_identity_pool_provider.github.name
}
