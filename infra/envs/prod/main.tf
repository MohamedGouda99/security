terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.17.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.17.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

locals {
  app_subnet_name    = "${var.network_name}-app-${var.environment}"
  data_subnet_name   = "${var.network_name}-data-${var.environment}"
  pod_range_name     = "pods-${var.environment}"
  service_range_name = "services-${var.environment}"
  labels_common      = merge(var.labels, { environment = var.environment })
  cloud_run_service_account = coalesce(
    var.cloud_run_service_account,
    module.iam.app_service_account_email,
  )
  cloud_run_image_uri = coalesce(
    var.cloud_run_image,
    "${var.region}-docker.pkg.dev/${var.project_id}/chatbot-models-${var.environment}/chatbot:latest",
  )
}

module "networking" {
  source       = "../../modules/networking"
  project_id   = var.project_id
  network_name = var.network_name
  region       = var.region

  subnets = [
    {
      name          = local.app_subnet_name
      ip_cidr_range = var.app_subnet_cidr
      secondary_ranges = [
        {
          range_name    = local.pod_range_name
          ip_cidr_range = var.pod_secondary_cidr
        },
        {
          range_name    = local.service_range_name
          ip_cidr_range = var.service_secondary_cidr
        }
      ]
    },
    {
      name                  = local.data_subnet_name
      ip_cidr_range         = var.data_subnet_cidr
      secondary_ranges      = []
      private_google_access = true
    }
  ]
}

module "iam" {
  source                    = "../../modules/iam"
  project_id                = var.project_id
  github_repositories       = var.github_repositories
  cicd_service_account_id   = "cicd-${var.environment}"
  app_service_account_id    = "app-${var.environment}"
  vertex_service_account_id = "vertex-${var.environment}"
}

module "logging" {
  source             = "../../modules/logging"
  project_id         = var.project_id
  location           = "global"
  bigquery_location  = "US"
  gcs_archive_bucket = var.archive_bucket_name
  pubsub_topic_id    = var.notification_channel_topic
}

module "security" {
  source                  = "../../modules/security"
  project_id              = var.project_id
  notification_topic      = module.logging.incident_topic
  security_scanner_target = var.security_scanner_target
}

module "gke" {
  source                       = "../../modules/gke"
  project_id                   = var.project_id
  name                         = "chatbot-gke-${var.environment}"
  region                       = var.region
  network                      = module.networking.network_id
  subnetwork                   = module.networking.subnetwork_self_links[local.app_subnet_name]
  pod_secondary_range_name     = local.pod_range_name
  service_secondary_range_name = local.service_range_name
  master_ipv4_cidr_block       = var.gke_master_cidr
  master_authorized_ranges     = []
  labels                       = local.labels_common
}

module "vertex" {
  source                    = "../../modules/vertex"
  project_id                = var.project_id
  location                  = var.region
  dataset_bucket_name       = var.dataset_bucket_name
  artifact_registry_repo_id = "chatbot-models-${var.environment}"
  network                   = module.networking.network_id
  labels                    = merge(local.labels_common, var.vertex_labels)
}

module "cloudrun" {
  source                = "../../modules/cloudrun"
  project_id            = var.project_id
  location              = var.region
  service_name          = "chatbot-edge-${var.environment}"
  image                 = local.cloud_run_image_uri
  service_account_email = local.cloud_run_service_account
  env_vars = {
    ENVIRONMENT = var.environment
    PROJECT_ID  = var.project_id
  }
  allow_unauthenticated = false
  min_instances         = 1
}

module "cloudbuild" {
  source          = "../../modules/cloudbuild"
  project_id      = var.project_id
  github_owner    = split("/", var.github_repositories[0])[0]
  github_name     = split("/", var.github_repositories[0])[1]
  image_uri       = local.cloud_run_image_uri
  service_account = module.iam.cicd_service_account_email
}
