# Infrastructure-as-Code Overview

This directory contains Terraform modules and environment definitions for the secure ML chatbot platform.

- `modules/` keeps reusable building blocks (networking, GKE, Vertex AI, IAM, logging, security, Cloud Run, Cloud Build).
- `envs/dev` and `envs/prod` compose the modules for each environment. Copy the `terraform.tfvars.example` and `backend.tf.example` files to bootstrap state and variables.
- `policies/` will store policy-as-code artifacts enforced via GitHub Actions.

## Usage
1. Rename `backend.tf.example` to `backend.tf` and update the remote state bucket.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust values.
3. Run `terraform init`, `terraform validate`, and `terraform plan` from the desired environment folder.
4. Apply changes only through the GitHub Actions pipeline to maintain auditability.