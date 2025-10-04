locals {
  env = [for k, v in var.env_vars : {
    name  = k
    value = v
  }]

  service_annotations = merge(
    {
      "run.googleapis.com/ingress"               = var.ingress
      "run.googleapis.com/execution-environment" = "gen2"
    },
    var.min_instances > 0 ? {
      "autoscaling.knative.dev/minScale" = tostring(var.min_instances)
    } : {},
    var.max_instances > 0 ? {
      "autoscaling.knative.dev/maxScale" = tostring(var.max_instances)
    } : {}
  )

  template_annotations = merge(
    {
      "run.googleapis.com/execution-environment" = "gen2"
    },
    var.vpc_connector == null ? {} : {
      "run.googleapis.com/vpc-access-connector" = var.vpc_connector
      "run.googleapis.com/vpc-access-egress"    = "all-traffic"
    }
  )
}

resource "google_cloud_run_service" "service" {
  project  = var.project_id
  name     = var.service_name
  location = var.location

  metadata {
    annotations = local.service_annotations
  }

  template {
    metadata {
      annotations = local.template_annotations
    }

    spec {
      containers {
        image = var.image

        ports {
          name           = "http1"
          container_port = 8080
        }

        dynamic "env" {
          for_each = local.env
          content {
            name  = env.value.name
            value = env.value.value
          }
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
      }

      service_account_name = var.service_account_email
      timeout_seconds      = 60
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  count    = var.allow_unauthenticated ? 1 : 0
  project  = var.project_id
  location = var.location
  service  = google_cloud_run_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_compute_region_network_endpoint_group" "neg" {
  count                 = var.create_neg ? 1 : 0
  name                  = "${var.service_name}-neg"
  project               = var.project_id
  region                = var.location
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_service.service.name
  }
}
