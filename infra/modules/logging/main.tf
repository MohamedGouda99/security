resource "google_logging_project_bucket_config" "security" {
  project        = var.project_id
  bucket_id      = "security-buffer"
  location       = var.location
  retention_days = var.log_bucket_retention_days
}

resource "google_bigquery_dataset" "security" {
  project                     = var.project_id
  dataset_id                  = var.bigquery_dataset_id
  location                    = var.bigquery_location
  description                 = "Central analytics dataset for security telemetry."
  default_table_expiration_ms = null
  labels = {
    purpose = "security"
  }
}

resource "google_storage_bucket" "archive" {
  project                     = var.project_id
  name                        = var.gcs_archive_bucket
  location                    = upper(var.bigquery_location)
  force_destroy               = false
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }

  retention_policy {
    retention_period = 31536000
  }
}

resource "google_pubsub_topic" "ir" {
  project                    = var.project_id
  name                       = var.pubsub_topic_id
  message_retention_duration = "604800s"
  labels = {
    purpose = "incident-response"
  }
}

resource "google_logging_project_sink" "security_bq" {
  project                = var.project_id
  name                   = "security-bq-sink"
  destination            = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.security.dataset_id}"
  filter                 = var.log_filter_high_value
  unique_writer_identity = true
}

resource "google_bigquery_dataset_iam_member" "security_writer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.security.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.security_bq.writer_identity
}

resource "google_logging_project_sink" "security_archive" {
  project                = var.project_id
  name                   = "security-archive-sink"
  destination            = "storage.googleapis.com/${google_storage_bucket.archive.name}"
  filter                 = "severity>=NOTICE"
  unique_writer_identity = true
}

resource "google_storage_bucket_iam_member" "archive_writer" {
  bucket = google_storage_bucket.archive.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.security_archive.writer_identity
}

resource "google_logging_project_sink" "security_pubsub" {
  project                = var.project_id
  name                   = "security-pubsub-sink"
  destination            = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.ir.name}"
  filter                 = "severity>=WARNING"
  unique_writer_identity = true
}

resource "google_pubsub_topic_iam_member" "sink_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.ir.name
  role    = "roles/pubsub.publisher"
  member  = google_logging_project_sink.security_pubsub.writer_identity
}

