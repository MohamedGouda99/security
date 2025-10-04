# Secure ML Chatbot Platform - Architecture and Automation Plan

## 1. Objectives
- Deliver an enterprise-ready ML chatbot platform with end-to-end automation (Terraform + GitHub Actions).
- Enforce security across network, workload, data, and operations with measurable controls.
- Provide comparative evaluation of AWS, Azure, and GCP to justify GCP selection.

## 2. Cloud Comparison Snapshot
| Capability | AWS | Azure | GCP |
| --- | --- | --- | --- |
| Managed ML and GenAI | Amazon SageMaker, Bedrock (broad service catalog, complex governance) | Azure ML, Azure OpenAI (tight M365/AD integration, regional feature lag) | Vertex AI, PaLM/Codey (unified console + pipelines, tight Anthos/GKE integration) |
| Networking and Zero Trust | VPC, PrivateLink, AWS Verified Access (strong but perimeter-focused) | VNets, Private Link, Defender for Cloud (deep AD integration) | VPC Service Controls, BeyondCorp Enterprise (identity-centric, service perimeter) |
| Security Operations | GuardDuty, Security Hub, Detective (strong, fragmented dashboards) | Sentinel SIEM, Defender suite (cohesive, licensing heavy) | Security Command Center, Chronicle SIEM, Event Threat Detection (native integration, real-time) |
| Terraform and Automation | Mature provider, best for IAM policies (complex multi-account) | Provider parity improving (some gaps) | First-class provider, Blueprints, policy-trees (less toil) |
| Cost and Efficiency | Flexible but noisy cost model | Reserved instances commitments | Preemptible TPU/GPU, sustained-use discounts, global load balancer |

**Why GCP**
1. Vertex AI streamlines the full ML lifecycle (data -> feature store -> training -> registry -> endpoint) with native CI/CD hooks.
2. Identity-centric security (VPC Service Controls, IAM Conditions, BeyondCorp) reduces reliance on perimeter defenses and eases SaaS/API protection for the chatbot.
3. Built-in security operations (Security Command Center, Chronicle, Event Threat Detection) integrate with Cloud Logging/Monitoring for rapid incident response.
4. Terraform support is deep (official modules, policy libraries) enabling repeatable provisioning with policy-as-code.

## 3. Target GCP Architecture Overview
```mermaid
flowchart LR
    subgraph GitHub ["GitHub Org"]
        GA[GitHub Actions\nCI/CD]
        Repo[Infrastructure and App Repos]
    end

    subgraph Security ["Security and Governance"]
        SCC[Security Command Center]
        Chronicle[Chronicle SIEM]
        Policy[OPA/Conftest\nPolicy-as-Code]
    end

    subgraph Landing["GCP Landing Zone"]
        subgraph Network["Shared VPC (Hub)"]
            LB[External HTTPS Load Balancer]
            Armor[Cloud Armor WAF/Bot Mgmt]
            CDN[Cloud CDN]
            SubApp[App Subnet]
            SubData[Data Subnet]
            NAT[Cloud NAT]
            PSC[Private Service Connect]
        end

        subgraph Runtime["App Runtime"]
            Run[Cloud Run API Gateway]
            GKE[GKE Autopilot\nChatbot Services]
            VertexSvc[Vertex AI Endpoints\nPrediction Services]
            Secret[Secret Manager + Cloud KMS]
            Artifact[Artifact Registry]
        end

        subgraph ML["Vertex AI Platform"]
            Pipelines[Vertex Pipelines]
            Training[Vertex Training Jobs]
            Registry[Model Registry]
            Feature[Feature Store]
            Storage[Cloud Storage (Artifacts and Datasets)]
            BQ[BigQuery (Analytics)]
        end

        subgraph Data["State and Services"]
            SQL[Cloud SQL or Firestore (Optional)]
            Cache[Cloud Memorystore (Optional)]
        end

        subgraph Observability["Monitoring and IR"]
            Logging[Cloud Logging]
            Metrics[Cloud Monitoring]
            PubSub[Pub/Sub IR Events]
            IR[Cloud Functions or Workflows\nIncident Automation]
        end
    end

    Repo --> GA
    GA -->|Terraform Plan or Apply\nWorkload Identity Federation| Network
    GA -->|Container Build or Test| Artifact
    GA -->|Model Deploy| VertexSvc
    GA --> Policy

    LB --> Armor --> CDN --> Run --> GKE
    GKE --> VertexSvc
    GKE --> Secret
    Run --> Secret

    GKE -->|Model Fetch| Artifact
    GKE -->|Training Requests| Pipelines
    Pipelines --> Training --> Registry --> VertexSvc
    Training --> Storage
    Feature --> Training
    Feature --> VertexSvc
    GKE --> SQL
    GKE --> Cache

    Logging --> SCC
    Logging --> Chronicle
    Metrics --> SCC
    Chronicle --> IR
    PubSub --> IR
    SCC --> IR
    Network --> Logging
    Runtime --> Logging
    ML --> Logging
    Data --> Logging

    NAT --> GKE
    PSC --> VertexSvc
    Secret --> Runtime
    Armor --> reCAPTCHA[[reCAPTCHA Enterprise]]
```

## 4. Security Controls Mapping
| Requirement | Control Set |
| --- | --- |
| Network protocols and segmentation | Shared VPC with tiered subnets, private service endpoints, Cloud NAT, enforced TLS 1.2+, mTLS for east-west on GKE, Cloud Armor geo/IP filtering |
| Web application security | HTTPS load balancer + Cloud Armor managed rules, reCAPTCHA Enterprise, OAuth2/IAP for admin UIs, CSP headers, Binary Authorization for container images |
| Security assessments and pentest | CI integrates Trivy, Checkov, Bandit, Kube-bench; SCC Security Health Analytics; scheduled DAST via Cloud Build or third-party; Terraform policy-as-code gates |
| Authentication and access control | Workload Identity Federation (GitHub -> GCP), IAM Conditions and least privilege roles, IAP for admin plane, BeyondCorp Enterprise for workforce, Secret Manager backed by CMEK |
| Security monitoring and intrusion detection | Cloud Logging/Monitoring -> SCC Event Threat Detection, Chronicle SIEM, IDS signals from Cloud Armor; alerting to PagerDuty or Slack |
| Incident response and forensics | Log sinks with immutability (BigQuery + Cloud Storage), IR automation via Cloud Functions or Workflows, Artifact Registry immutability, disk snapshots, playbooks stored in repo |
| Security tooling development | Python-based policy bot invoking SCC Findings API, Terraform policy libraries (OPA/Conftest) enforced in CI, custom analyzers for log enrichment |
| Automation or frameworks | Terraform module composition per environment, GitHub Actions workflow automation, Vertex Pipelines for continuous training, Cloud Deploy/Build as optional managed CI steps |

## 5. Terraform Structure (Planned)
```
infra/
  modules/
    networking/
    gke/
    vertex/
    iam/
    security/
    logging/
  envs/
    dev/
      main.tf
      variables.tf
      outputs.tf
    prod/
      ...
  global/
    backend.tf
    providers.tf
policies/
  opa/
  terraform-validator/
```
- Remote state stored in GCS bucket (per environment) with versioning and CMEK.
- Terraform Cloud optional; GitHub Actions uses `terraform fmt` -> `validate` -> `plan` -> approval -> `apply`.
- Policy guardrails via Conftest (OPA) + Google Config Validator.

## 6. GitHub Actions Workflow Outline
1. prepare - checkout, cache deps, run `pip install -r requirements-dev.txt`.
2. lint - `ruff`/`black --check`, `bandit`, `mypy` (optional).
3. tests - `pytest` with coverage.
4. iac-static - `terraform fmt -check`, `terraform validate`, `checkov`, `conftest test`.
5. build-image - Build container with Cloud Build using OIDC to Artifact Registry, scan with Trivy.
6. plan - `terraform plan` for target environment, upload artifact.
7. approval - manual gate for protected branches.
8. apply - `terraform apply` (prod requires approval).
9. deploy-model - Trigger Vertex Pipeline run for model promotion.
10. post-deploy - Smoke tests (Locust/pytest), log baseline check.

## 7. Python Chatbot Application (Planned)
- FastAPI service exposing `/chat` endpoint with JWT-based auth (Google Identity Tokens).
- Integrates with Vertex AI text model via REST or gRPC; fallback to local mock for dev.
- Input validation, rate limiting (Redis/Cloud Memorystore), audit logging to Cloud Logging.
- Security: use Pydantic validation, secrets loaded from Secret Manager, dependency pinning.
- Provide CLI tooling for security/ops automation (log triage, config checks).

## 8. Incident Response and Forensics
- `logging/` Terraform module creates sinks to BigQuery (hot) + Cloud Storage (cold) with retention and CMEK.
- Chronicle integration via Pub/Sub export for threat hunting.
- IR runbooks stored in repo; automation triggers isolate compromised workloads (GKE namespace quarantine via Cloud Functions).

## 9. Next Steps
1. Implement Terraform modules and environment stacks.
2. Scaffold FastAPI chatbot service with secure defaults and tests.
3. Add GitHub Actions workflows, policy-as-code bundles, and documentation for operations.
4. Conduct dry-run (`terraform plan`) and smoke-test of application locally.