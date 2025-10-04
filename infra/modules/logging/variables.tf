variable "project_id" {
  description = "Project ID for logging resources."
  type        = string
}

variable "location" {
  description = "Location for regional resources (BigQuery/PubSub)."
  type        = string
  default     = "us-central1"
}

variable "log_bucket_retention_days" {
  description = "Retention period for the default logging bucket."
  type        = number
  default     = 30
}

variable "bigquery_dataset_id" {
  description = "ID for the BigQuery dataset storing analytical logs."
  type        = string
  default     = "security_logs"
}

variable "bigquery_location" {
  description = "BigQuery dataset location."
  type        = string
  default     = "US"
}

variable "gcs_archive_bucket" {
  description = "Name for the archival Cloud Storage bucket."
  type        = string
}

variable "pubsub_topic_id" {
  description = "Pub/Sub topic for incident response triggers."
  type        = string
  default     = "ir-events"
}

variable "log_filter_high_value" {
  description = "Advanced Logs Query filter for high-value security findings."
  type        = string
  default     = "resource.type=\"k8s_container\" AND severity>=ERROR"
}