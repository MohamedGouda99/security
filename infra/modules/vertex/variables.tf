variable "project_id" {
  description = "Project hosting Vertex AI resources."
  type        = string
}

variable "location" {
  description = "Vertex AI regional location (for example us-central1)."
  type        = string
}

variable "dataset_bucket_name" {
  description = "GCS bucket for training datasets and artifacts."
  type        = string
}

variable "artifact_registry_repo_id" {
  description = "Artifact Registry repository ID for models or containers."
  type        = string
  default     = "chatbot-models"
}

variable "network" {
  description = "Optional VPC network self link for private services."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels applied to Vertex resources."
  type        = map(string)
  default     = {}
}