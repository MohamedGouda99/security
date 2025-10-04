output "enabled_services" {
  description = "List of security-focused APIs enabled."
  value       = [for s in google_project_service.security : s.service]
}

output "notification_config_id" {
  description = "SCC notification config resource name."
  value       = try(google_scc_notification_config.findings[0].name, null)
}
