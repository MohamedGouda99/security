variable "project_id" {
  description = "GCP project ID for this environment."
  type        = string
}

variable "region" {
  description = "Primary region for resources."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "github_repositories" {
  description = "GitHub repositories allowed to deploy via OIDC."
  type        = list(string)
}

variable "network_name" {
  description = "Name of the shared VPC."
  type        = string
  default     = "chatbot-shared-vpc"
}

variable "app_subnet_cidr" {
  description = "Primary subnet CIDR for application tier."
  type        = string
  default     = "10.10.0.0/24"
}

variable "data_subnet_cidr" {
  description = "Subnet CIDR for data services."
  type        = string
  default     = "10.10.10.0/24"
}

variable "pod_secondary_cidr" {
  description = "Secondary CIDR for GKE pods."
  type        = string
  default     = "10.20.0.0/16"
}

variable "service_secondary_cidr" {
  description = "Secondary CIDR for GKE services."
  type        = string
  default     = "10.21.0.0/22"
}

variable "gke_master_cidr" {
  description = "CIDR block for private GKE control plane."
  type        = string
  default     = "172.16.0.0/28"
}

variable "dataset_bucket_name" {
  description = "Dataset bucket for Vertex AI."
  type        = string
}

variable "archive_bucket_name" {
  description = "Log archive bucket."
  type        = string
}

variable "cloud_run_image" {
  description = "Container image for the Cloud Run edge service."
  type        = string
}

variable "cloud_run_service_account" {
  description = "Service account email for Cloud Run runtime. Leave null to use module output."
  type        = string
  default     = null
}

variable "vertex_labels" {
  description = "Labels to apply to Vertex resources."
  type        = map(string)
  default     = {}
}

variable "notification_channel_topic" {
  description = "Pub/Sub topic name for SCC notifications (without prefix)."
  type        = string
  default     = "security-ir"
}

variable "security_scanner_target" {
  description = "Public URL for scheduled DAST scans."
  type        = string
  default     = null
}

variable "labels" {
  description = "Common labels applied to resources."
  type        = map(string)
  default     = {}
}
