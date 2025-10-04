# CI/CD Pipeline Overview

This repository uses GitHub Actions with workload identity federation to deploy into GCP.

- `ci.yml` executes linting, typing, tests, Terraform validation, Checkov, and OPA policy tests on every push and pull request.
- `deploy.yml` performs container builds, Terraform apply, and post-deployment smoke tests when invoked manually with the target environment.
- `policies/` hosts OPA and Terraform Validator policies that run in CI and guard infrastructure changes.
- `scripts/security_checks.sh` mirrors the CI pipeline locally.

Secrets expected in GitHub:
- `WIF_PROVIDER` and `TERRAFORM_SA` for workload identity.
- `GCP_PROJECT_ID` and `GCP_REGION` for Cloud Build and Terraform.
- `TF_VARS_DEV` / `TF_VARS_PROD` containing the environment-specific Terraform variable definitions.