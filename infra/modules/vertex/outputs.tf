output "dataset_bucket" {
  description = "Dataset bucket name."
  value       = google_storage_bucket.datasets.name
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository resource name."
  value       = google_artifact_registry_repository.models.id
}

output "featurestore_id" {
  description = "Vertex AI Feature Store resource name."
  value       = google_vertex_ai_featurestore.chatbot.id
}

output "endpoint_id" {
  description = "Vertex AI endpoint resource name."
  value       = google_vertex_ai_endpoint.chatbot.id
}
