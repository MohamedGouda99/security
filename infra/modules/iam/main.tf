resource "google_service_account" "cicd" {
  project      = var.project_id
  account_id   = var.cicd_service_account_id
  display_name = "CI/CD Automation"
}

resource "google_service_account" "app" {
  project      = var.project_id
  account_id   = var.app_service_account_id
  display_name = "Chatbot Runtime"
}

resource "google_service_account" "vertex" {
  project      = var.project_id
  account_id   = var.vertex_service_account_id
  display_name = "Vertex Pipelines"
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = var.workload_identity_pool_id
  display_name              = var.workload_identity_pool_display_name
  description               = "Federated identities for GitHub Actions."
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.workload_identity_provider_id
  display_name                       = "GitHub OIDC"
  description                        = "OIDC provider for GitHub Actions."

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.actor"      = "assertion.actor"
    "attribute.workflow"   = "assertion.workflow"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

locals {
  github_principal_sets = [for repo in var.github_repositories : "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${repo}"]
}

resource "google_service_account_iam_binding" "cicd_federated" {
  service_account_id = google_service_account.cicd.name
  role               = "roles/iam.workloadIdentityUser"
  members            = local.github_principal_sets
}

resource "google_project_iam_member" "cicd" {
  for_each = toset(var.cicd_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.cicd.email}"
}

resource "google_project_iam_member" "app" {
  for_each = toset(var.app_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.app.email}"
}

resource "google_project_iam_member" "vertex" {
  for_each = toset(var.vertex_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.vertex.email}"
}

