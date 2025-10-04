output "network_id" {
  description = "ID of the provisioned VPC network."
  value       = google_compute_network.vpc.id
}

output "subnetwork_self_links" {
  description = "Self links for created subnets."
  value       = { for name, subnet in google_compute_subnetwork.subnets : name => subnet.self_link }
}

output "security_policy" {
  description = "Cloud Armor policy resource if created."
  value       = try(google_compute_security_policy.baseline[0].self_link, null)
}
