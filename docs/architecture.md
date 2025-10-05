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
            PSCNode[Private Service Connect]
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
            Storage["Cloud Storage &#40;Artifacts and Datasets&#41;"]
            BQ["BigQuery &#40;Analytics&#41;"]
        end

        subgraph Data["State and Services"]
            SQL["Cloud SQL or Firestore &#40;Optional&#41;"]
            Cache["Cloud Memorystore &#40;Optional&#41;"]
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
    PSCNode --> VertexSvc
    Secret --> Runtime
    Armor --> reCAPTCHA[[reCAPTCHA Enterprise]]
