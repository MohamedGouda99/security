variable "project_id" {
  description = "Project ID hosting the Cloud Run service."
  type        = string
}

variable "location" {
  description = "Region for the Cloud Run service."
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name."
  type        = string
}

variable "image" {
  description = "Container image URI for deployment."
  type        = string
}

variable "service_account_email" {
  description = "Service account email used by the Cloud Run service."
  type        = string
}

variable "env_vars" {
  description = "Environment variables injected into the container."
  type        = map(string)
  default     = {}
}

variable "vpc_connector" {
  description = "Optional Serverless VPC Connector name."
  type        = string
  default     = null
}

variable "ingress" {
  description = "Ingress setting (all, internal, internal-and-cloud-load-balancing)."
  type        = string
  default     = "internal-and-cloud-load-balancing"
}

variable "min_instances" {
  description = "Minimum number of container instances."
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of container instances."
  type        = number
  default     = 5
}

variable "allow_unauthenticated" {
  description = "Allow unauthenticated invocation."
  type        = bool
  default     = false
}

variable "create_neg" {
  description = "Create a serverless network endpoint group for load balancing."
  type        = bool
  default     = true
}