output "trigger_id" {
  description = "Cloud Build trigger identifier."
  value       = google_cloudbuild_trigger.container.id
}
