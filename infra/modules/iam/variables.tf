variable "project_id" {
  description = "Target project ID."
  type        = string
}

variable "github_repositories" {
  description = "GitHub repositories authorized for workload identity federation (format org/repo)."
  type        = list(string)
}

variable "workload_identity_pool_id" {
  description = "Identifier for the workload identity pool."
  type        = string
  default     = "github-actions"
}

variable "workload_identity_pool_display_name" {
  description = "Display name for the workload identity pool."
  type        = string
  default     = "GitHub Actions Pool"
}

variable "workload_identity_provider_id" {
  description = "Identifier for the workload identity provider."
  type        = string
  default     = "github"
}

variable "cicd_service_account_id" {
  description = "Service account ID for CI/CD automation."
  type        = string
  default     = "cicd-automation"
}

variable "app_service_account_id" {
  description = "Service account ID for the application workloads."
  type        = string
  default     = "chatbot-runtime"
}

variable "vertex_service_account_id" {
  description = "Service account ID for Vertex AI pipelines."
  type        = string
  default     = "vertex-pipeline"
}

variable "cicd_roles" {
  description = "Roles applied to the CI/CD service account."
  type        = list(string)
  default = [
    "roles/compute.networkAdmin",
    "roles/iam.serviceAccountUser",
    "roles/resourcemanager.projectIamAdmin",
    "roles/container.admin",
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
    "roles/storage.admin"
  ]
}

variable "app_roles" {
  description = "Roles applied to the runtime service account."
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor"
  ]
}

variable "vertex_roles" {
  description = "Roles applied to the Vertex AI service account."
  type        = list(string)
  default = [
    "roles/aiplatform.admin",
    "roles/storage.objectAdmin",
    "roles/iam.serviceAccountUser"
  ]
}