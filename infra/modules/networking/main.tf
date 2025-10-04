locals {
  primary_region = var.region
  parsed_subnets = { for subnet in var.subnets : subnet.name => subnet }
}

resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "subnets" {
  for_each                 = local.parsed_subnets
  project                  = var.project_id
  name                     = each.value.name
  ip_cidr_range            = each.value.ip_cidr_range
  region                   = coalesce(each.value.region, local.primary_region)
  network                  = google_compute_network.vpc.id
  private_ip_google_access = each.value.private_google_access

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  log_config {
    metadata = each.value.flow_logs ? "INCLUDE_ALL_METADATA" : "EXCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "this" {
  count   = var.nat_enabled ? 1 : 0
  name    = "${var.network_name}-router"
  project = var.project_id
  region  = local.primary_region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "this" {
  count = var.nat_enabled ? 1 : 0

  name                                = "${var.network_name}-nat"
  project                             = var.project_id
  region                              = local.primary_region
  router                              = google_compute_router.this[0].name
  nat_ip_allocate_option              = "AUTO_ONLY"
  min_ports_per_vm                    = 128
  udp_idle_timeout_sec                = 30
  tcp_established_idle_timeout_sec    = 1200
  tcp_time_wait_timeout_sec           = 120
  icmp_idle_timeout_sec               = 30
  enable_endpoint_independent_mapping = true
  source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ALL"
  }
}

resource "google_compute_firewall" "allow_lb_healthchecks" {
  project = var.project_id
  name    = "${var.network_name}-allow-hc"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  direction = "INGRESS"
  priority  = 1000
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]
  target_tags = ["lb-backend"]
}

resource "google_compute_firewall" "allow_iap" {
  project = var.project_id
  name    = "${var.network_name}-allow-iap"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "3389", "10250"]
  }

  direction     = "INGRESS"
  priority      = 1001
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-access"]
}

resource "google_compute_security_policy" "baseline" {
  count       = var.create_security_policy ? 1 : 0
  name        = "${var.network_name}-armor"
  description = "Baseline Cloud Armor policy for ${var.network_name}"
  type        = "CLOUD_ARMOR"

  rule {
    priority    = 1000
    description = "Block SQL injection patterns"
    action      = "deny(403)"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sqli-v33-stable')"
      }
    }
  }

  rule {
    priority    = 1001
    description = "Block XSS patterns"
    action      = "deny(403)"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('xss-v33-stable')"
      }
    }
  }

  dynamic "rule" {
    for_each = var.security_policy_rules
    iterator = custom_rule
    content {
      priority    = custom_rule.value.priority
      description = custom_rule.value.description
      action      = custom_rule.value.action
      match {
        expr {
          expression = custom_rule.value.expression
        }
      }
    }
  }

  rule {
    priority = 2147483647
    action   = "allow"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}
