variable "project_id" {
  description = "Project ID for Cloud Build trigger."
  type        = string
}

variable "trigger_name" {
  description = "Trigger name."
  type        = string
  default     = "chatbot-container-build"
}

variable "github_owner" {
  description = "GitHub repository owner."
  type        = string
}

variable "github_name" {
  description = "GitHub repository name."
  type        = string
}

variable "branch_pattern" {
  description = "Regex for branches that start the trigger."
  type        = string
  default     = "^main$"
}

variable "image_uri" {
  description = "Container image URI to build and push."
  type        = string
}

variable "service_account" {
  description = "Service account email used by the trigger."
  type        = string
}

variable "substitutions" {
  description = "Optional substitution variables for Cloud Build."
  type        = map(string)
  default     = {}
}