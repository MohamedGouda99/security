resource "google_cloudbuild_trigger" "container" {
  project = var.project_id
  name    = var.trigger_name

  github {
    owner = var.github_owner
    name  = var.github_name
    push {
      branch = var.branch_pattern
    }
  }

  substitutions   = var.substitutions
  service_account = var.service_account

  build {
    step {
      name = "gcr.io/cloud-builders/docker"
      args = [
        "build",
        "-t",
        var.image_uri,
        "."
      ]
    }

    step {
      name = "gcr.io/cloud-builders/docker"
      args = [
        "push",
        var.image_uri
      ]
    }

    images = [var.image_uri]
  }
}

