variable "project_id" {
  description = "GCP project ID to host the network."
  type        = string
}

variable "network_name" {
  description = "Name for the VPC network."
  type        = string
}

variable "region" {
  description = "Primary region for regional resources."
  type        = string
}

variable "subnets" {
  description = "List of subnet definitions with optional secondary ranges."
  type = list(object({
    name                  = string
    ip_cidr_range         = string
    region                = optional(string)
    private_google_access = optional(bool, true)
    flow_logs             = optional(bool, true)
    secondary_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
  }))
}

variable "nat_enabled" {
  description = "Whether to provision Cloud NAT for outbound traffic."
  type        = bool
  default     = true
}

variable "create_security_policy" {
  description = "Controls creation of a baseline Cloud Armor security policy."
  type        = bool
  default     = true
}

variable "security_policy_rules" {
  description = "Optional list of Cloud Armor rules to append to the baseline policy."
  type = list(object({
    priority    = number
    description = optional(string, "")
    action      = string
    expression  = string
  }))
  default = []
}