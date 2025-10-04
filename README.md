# Secure ML Chatbot Platform

This repository contains a production-style Google Cloud Platform (GCP) landing zone and AI chatbot workload. It highlights network security, data protection, governance, and automation patterns, along with interview-ready collateral (docs, slides, automation scripts).

## Repository Layout

```
ap/                        # Python FastAPI chatbot service (skeleton)
docs/                      # Client briefing and crash-course documentation
infra/                     # Terraform modules and environment stacks
policies/                  # OPA policy bundles
scripts/                   # Security automation helpers
reports/                   # Generated JSON/Markdown reports (gitignored)
```

## Security Automation Scripts

### `scripts/security_checks.sh`
Legacy bash helper that installs dependencies, runs linting, typing, tests, Terraform validation, Checkov, and OPA policy checks.

### `scripts/security_checks.py`
Python port of the shell helper. Executes:
- `pip install -e app[dev]`
- `ruff`, `mypy`, `pytest`
- `terraform fmt`, `init -backend=false`, `validate`
- `checkov`, `opa test`

Halts on first failure and prints JSON summary.

### `scripts/advanced_security_pipeline.py`
Enhanced pipeline runner with:
- Terraform plan generation and JSON export for OPA evaluation
- Sequential checks (ruff, mypy, pytest, terraform fmt/validate, Checkov, OPA eval, Trivy)
- Structured results, hints, duration per step
- Reports written to `reports/security-run-*.json` and `*.md`
- Optional `--skip-plan` flag to reuse an existing plan JSON

Dependencies: `ruff`, `mypy`, `pytest`, `terraform`, `checkov`, `opa`, `trivy`, optional `rich` for pretty output.

## Interview Collateral

- `docs/client_briefing.docx`: polished narrative describing architecture, controls, automation.
- `security-crash-course.docx`: classic-format crash course for discussion.
- `security-crash-course.pptx`: minimal deck ready for custom styling.

## Ignored Assets (`.gitignore`)

- Node artifacts (`app/node_modules/`, `dist/`, `.env*`, logs)
- Python virtual environments (`app/.venv/`, `infra/envs/prod/.venv/`, `.venv/`)
- Terraform working directories and state (`**/.terraform/`, terraform state files, crash logs)
- Reports and generated artifacts (`reports/`, `artifacts/`)
- IDE/OS clutter (`.vscode/`, `.idea/`, `.DS_Store`, etc.)
- Secrets and certificates (`*.pem`, `*.key`, `*.crt`, `*.pfx`)
- Temporary files (`*.log`, `*.tmp`, `*.swp`, `~$*`)

## Running Automation

```bash
# Basic checks
toolbox$ python scripts/security_checks.py

# Full pipeline with plan/OPA/Trivy and reports
toolbox$ python scripts/advanced_security_pipeline.py
# Reuse existing plan.json if already generated
toolbox$ python scripts/advanced_security_pipeline.py --skip-plan
```

Reports land in `reports/` and are git-ignored.

## Common Security Themes Covered

- Network security: shared VPC segmentation, Cloud Armor, mutual TLS, workload identity
- Data security: CMEK enforcement, Secret Manager, Artifact Registry signing
- Governance: Terraform + policy-as-code (OPA/Conftest), GitHub Actions approvals, devcontainer parity
- Automation: Python scripts orchestrating terraform, OPA, Checkov, Trivy
- Incident readiness: SCC, Chronicle, Pub/Sub automation, immutable log sinks

## Next Steps

1. Extend FastAPI service and tests as needed.
2. Flesh out policy bundles and Terraform modules per environment.
3. Integrate crash-course docs/slides into interview preparation.
4. Run security automation before commits or CI runs.

Feel free to customize documentation and deck styling, or expand automation scripts to match production workflows.
