# Architecture

## 1. Objective

This project implements a small but production-style Azure application platform. The goal is not only to deploy an application, but to demonstrate the full lifecycle around it: infrastructure provisioning, image build, release automation, identity, secret access, monitoring, alerting, troubleshooting, and rollback.

## 2. High-level architecture

```mermaid
flowchart TB
    DEV[Developer Workstation]
    GH[GitHub Repository]
    CI[GitHub Actions - CI]
    CD[GitHub Actions - CD]
    ACR[Azure Container Registry]
    AKS[Azure Kubernetes Service]
    APP[Flask Incident Application]
    KV[Azure Key Vault]
    UAMI[User-assigned Managed Identity]
    LAW[Log Analytics Workspace]
    DCR[Container Insights DCR/DCRA]
    ALERT[Azure Monitor Alert]
    AG[Action Group]

    DEV --> GH
    GH --> CI
    CI --> ACR
    CI --> CD
    CD --> AKS
    ACR --> AKS
    AKS --> APP

    APP --> UAMI
    UAMI --> KV

    AKS --> DCR
    DCR --> LAW
    LAW --> ALERT
    ALERT --> AG
```

## 3. Infrastructure architecture

Terraform manages the Azure foundation. A dedicated bootstrap layer creates remote-state resources, while the environment layer composes reusable modules.

```text
terraform/bootstrap
  -> Terraform state resource group
  -> Azure Storage account
  -> private state container
  -> state access role assignment

terraform/environments/dev
  -> resource-group module
  -> network module
  -> nsg module
  -> acr module
  -> monitoring module
  -> aks module
  -> key-vault module
  -> container-insights module
```

The separation is intentional. The backend must exist before the environment can use it, so state bootstrap is isolated from the main platform configuration.

## 4. Network design

The development environment uses a dedicated VNet and separate subnets for platform workloads.

```text
VNet: 10.10.0.0/16

snet-aks-dev: 10.10.1.0/24
snet-app-dev: 10.10.2.0/24
```

Network Security Groups are created independently and associated with the appropriate subnet. AKS uses Azure CNI Overlay for pod networking.

## 5. AKS design

The AKS cluster is configured with:

- Kubernetes RBAC.
- OIDC issuer enabled.
- AKS Workload Identity enabled.
- Azure CNI Overlay networking.
- Standard load balancer.
- Two system-pool nodes in the development environment.
- Explicit upgrade settings.
- Azure Monitor / Container Insights integration.

The application deployment uses two baseline replicas and the following rolling-update behavior:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0
    maxSurge: 1
```

This protects the existing baseline capacity while a replacement pod is being created.

## 6. Container and image architecture

The Flask application is packaged in a Docker image based on `python:3.13-slim` and runs with Gunicorn as a non-root user.

The container includes:

- application code,
- templates and static files,
- Python dependencies,
- health check,
- `APP_VERSION` and `ENVIRONMENT` runtime configuration.

Images are stored in ACR. The normal CI path tags each image with the Git commit SHA, providing immutable release traceability.

## 7. CI/CD architecture

### CI

```mermaid
flowchart LR
    PUSH[Push to main] --> LOGIN[Azure login via GitHub OIDC]
    LOGIN --> ACRLOGIN[ACR login]
    ACRLOGIN --> BUILD[Docker build]
    BUILD --> TAG[Tag with commit SHA]
    TAG --> PUSHIMG[Push to ACR]
```

### CD

```mermaid
flowchart LR
    CISUCCESS[Successful CI] --> SHA[Use CI head SHA]
    SHA --> AZLOGIN[Azure OIDC login]
    AZLOGIN --> AKSCONTEXT[Get AKS context]
    AKSCONTEXT --> VERIFY[Verify SHA image exists]
    VERIFY --> LINT[Helm lint]
    LINT --> UPGRADE[Helm upgrade/install]
    UPGRADE --> WAIT[Wait for Ready rollout]
    WAIT --> VALIDATE[Validate image, pods, identity and Key Vault settings]
```

The CD workflow deploys the exact artifact produced by CI rather than rebuilding or resolving a mutable tag.

## 8. GitHub-to-Azure identity

GitHub Actions authenticates to Azure through a Microsoft Entra application with a federated credential scoped to the repository and branch.

```text
GitHub Actions OIDC token
  -> Entra federated identity credential
  -> short-lived Azure token
  -> Azure APIs / ACR / AKS
```

This removes the need to store a long-lived Azure client secret in GitHub.

## 9. AKS-to-Key Vault identity

The application uses AKS Workload Identity.

```mermaid
sequenceDiagram
    participant P as Incident App Pod
    participant SA as Kubernetes ServiceAccount
    participant E as Microsoft Entra ID
    participant MI as User-assigned Managed Identity
    participant KV as Azure Key Vault

    P->>SA: Uses projected service-account token
    SA->>E: Federated token exchange
    E->>MI: Resolve configured client identity
    MI->>KV: Request secret using RBAC
    KV-->>P: Secret value returned to application
```

The Kubernetes service account is annotated with the managed identity client ID and the pod template carries the workload identity label.

The Flask endpoint `/api/keyvault-check` validates access but never returns the secret value.

## 10. Monitoring architecture

The cluster sends telemetry to Log Analytics through Azure Monitor Agent and Container Insights.

```text
AKS
  -> Azure Monitor Agent (ama-logs)
  -> Data Collection Rule
  -> Data Collection Rule Association
  -> Log Analytics Workspace
  -> KQL
  -> Scheduled Query Alert
  -> Action Group
  -> Email notification
```

The project validated the following data sources:

- `KubePodInventory` for pod state and restarts.
- `ContainerLogV2` for container/application logs.
- `Perf` for CPU and memory metrics.
- `KubeEvents` for Kubernetes events.
- `KubeNodeInventory` for node inventory and state.

## 11. Release resilience behavior

A deliberate release using a nonexistent image tag proved the deployment strategy:

```mermaid
flowchart TD
    BAD[Helm upgrade with bad image tag]
    RS[New ReplicaSet created]
    PULL[Container runtime requests image]
    MISS[ACR tag does not exist]
    BACKOFF[ImagePullBackOff]
    OLD[Old 2 replicas remain Running]
    TIMEOUT[Helm wait times out]
    RCA[Root cause confirmed]
    ROLLBACK[Helm rollback]
    HEALTH[Health + Key Vault validation]

    BAD --> RS --> PULL --> MISS --> BACKOFF --> TIMEOUT
    BACKOFF --> OLD
    TIMEOUT --> RCA --> ROLLBACK --> HEALTH
```

The key reliability point is that `maxUnavailable: 0` prevented the failed new pod from reducing the two healthy existing replicas.

## 12. Design trade-offs

This is a development/portfolio environment, so some production controls are deliberately simplified. Examples include the AKS Free tier and public network access for services where private endpoints were not required for the learning goal.

For a production implementation, likely extensions would include private AKS/API access, private ACR/Key Vault endpoints, policy-as-code, separate system/user node pools, Pod Disruption Budgets, ingress with TLS, WAF, backup/DR design, image vulnerability scanning, environment promotion, and stronger release approval gates.
