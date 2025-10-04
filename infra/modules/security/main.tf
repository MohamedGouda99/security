resource "google_project_service" "security" {
  for_each           = toset(var.security_services)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_scc_notification_config" "findings" {
  provider = google-beta
  count    = var.organization_id == null ? 0 : 1

  organization = "organizations/${var.organization_id}"
  config_id    = "scc-notify"
  description  = "Push high severity SCC findings to Pub/Sub."
  pubsub_topic = var.notification_topic

  streaming_config {
    filter = "severity = \"HIGH\" OR severity = \"CRITICAL\""
  }

  depends_on = [google_project_service.security]
}

resource "google_logging_metric" "iam_policy_change" {
  project     = var.project_id
  name        = "iam-policy-change"
  description = "Metric tracking IAM policy modifications for alerting."
  filter      = "resource.type=\"audited_resource\" AND protoPayload.methodName=\"SetIamPolicy\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }

  label_extractors = {
    principal_email = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
  }
}

resource "google_monitoring_alert_policy" "iam_change" {
  project      = var.project_id
  display_name = "IAM Policy Change Alert"
  combiner     = "OR"

  conditions {
    display_name = "IAM Policy Change Spike"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/iam-policy-change\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "60s"
      trigger {
        count = 1
      }
    }
  }

  notification_channels = []
  documentation {
    content   = "Investigate unexpected IAM policy changes."
    mime_type = "text/markdown"
  }
}

resource "google_security_scanner_scan_config" "web" {
  provider = google-beta

  count         = var.security_scanner_target == null ? 0 : 1
  project       = var.project_id
  display_name  = "Chatbot Web DAST"
  max_qps       = 15
  starting_urls = [var.security_scanner_target]

  schedule {
    interval_duration_days = 7
  }

  target_platforms = ["COMPUTE"]
}
