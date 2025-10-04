output "logging_bucket_id" {
  description = "Identifier for the security logging bucket."
  value       = google_logging_project_bucket_config.security.name
}

output "bigquery_dataset" {
  description = "Security BigQuery dataset resource name."
  value       = google_bigquery_dataset.security.id
}

output "archive_bucket" {
  description = "Cloud Storage archive bucket name."
  value       = google_storage_bucket.archive.name
}

output "incident_topic" {
  description = "Incident response Pub/Sub topic."
  value       = google_pubsub_topic.ir.id
}
