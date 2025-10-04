resource "google_container_cluster" "autopilot" {
  provider = google-beta

  name     = var.name
  project  = var.project_id
  location = var.region

  enable_autopilot = true
  network          = var.network
  subnetwork       = var.subnetwork

  release_channel {
    channel = var.release_channel
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS", "APISERVER"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "HPA", "STORAGE"]

    managed_prometheus {
      enabled = true
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_secondary_range_name
    services_secondary_range_name = var.service_secondary_range_name
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  binary_authorization {
    evaluation_mode = var.enable_binary_authorization ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  }

  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_ranges) == 0 ? [] : [1]
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_ranges
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  mesh_certificates {
    enable_certificates = var.enable_mesh_certificates
  }

  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_DISABLED"
  }

  deletion_protection = true

  resource_labels = var.labels

  timeouts {
    create = "30m"
    update = "40m"
    delete = "45m"
  }
}
