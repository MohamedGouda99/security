resource "google_storage_bucket" "datasets" {
  project                     = var.project_id
  name                        = var.dataset_bucket_name
  location                    = upper(var.location)
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 180
    }
  }

  labels = var.labels
}

resource "google_artifact_registry_repository" "models" {
  project       = var.project_id
  location      = var.location
  repository_id = var.artifact_registry_repo_id
  description   = "Container and model artifacts for the chatbot platform."
  format        = "DOCKER"
  labels        = var.labels
}

resource "google_vertex_ai_featurestore" "chatbot" {
  provider = google-beta

  project = var.project_id
  region  = var.location
  name    = "chatbot-featurestore"
  labels  = var.labels

  online_serving_config {
    fixed_node_count = 1
  }
}

resource "google_vertex_ai_featurestore_entitytype" "session" {
  provider = google-beta

  name         = "${google_vertex_ai_featurestore.chatbot.name}/entityTypes/session-features"
  featurestore = google_vertex_ai_featurestore.chatbot.name
  description  = "Aggregated session signals for chatbot personalization."
  labels       = var.labels
}

resource "google_vertex_ai_endpoint" "chatbot" {
  provider = google-beta

  name         = "projects/${var.project_id}/locations/${var.location}/endpoints/chatbot-online-endpoint"
  location     = var.location
  display_name = "chatbot-online-endpoint"
  description  = "Online serving endpoint for chatbot model."
  labels       = var.labels
  network      = var.network
}

resource "google_vertex_ai_tensorboard" "chatbot" {
  provider = google-beta

  project      = var.project_id
  region       = var.location
  display_name = "chatbot-metrics"
  labels       = var.labels
}
