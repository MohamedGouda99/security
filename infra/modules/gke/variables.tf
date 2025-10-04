variable "project_id" {
  description = "GCP project ID hosting the cluster."
  type        = string
}

variable "name" {
  description = "Cluster name."
  type        = string
}

variable "region" {
  description = "Regional location for the Autopilot cluster."
  type        = string
}

variable "network" {
  description = "Self link of the VPC network."
  type        = string
}

variable "subnetwork" {
  description = "Self link of the subnetwork used by the cluster."
  type        = string
}

variable "pod_secondary_range_name" {
  description = "Secondary range name for pods."
  type        = string
}

variable "service_secondary_range_name" {
  description = "Secondary range name for services."
  type        = string
}

variable "release_channel" {
  description = "GKE release channel."
  type        = string
  default     = "REGULAR"
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the GKE control plane."
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_ranges" {
  description = "List of CIDR blocks allowed to reach the control plane."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "enable_binary_authorization" {
  description = "Enforce Binary Authorization policies on the cluster."
  type        = bool
  default     = true
}

variable "enable_mesh_certificates" {
  description = "Enable mesh certificates for workload identity federation."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Optional labels applied to the cluster."
  type        = map(string)
  default     = {}
}