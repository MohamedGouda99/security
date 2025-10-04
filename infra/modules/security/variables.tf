variable "project_id" {
  description = "Project ID for security services."
  type        = string
}

variable "notification_topic" {
  description = "Full Pub/Sub topic name for SCC notifications."
  type        = string
}

variable "organization_id" {
  description = "Optional organization numeric ID for SCC notification configs."
  type        = string
  default     = null
}

variable "security_services" {
  description = "APIs to enable for security posture."
  type        = list(string)
  default = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "cloudkms.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "aiplatform.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]
}

variable "security_scanner_target" {
  description = "App URL for Cloud Security Scanner."
  type        = string
  default     = null
}

variable "etag" {
  description = "Optional etag to control updates on notification config."
  type        = string
  default     = null
}
