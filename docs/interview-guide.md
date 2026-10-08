# Interview Guide

## 30-second project summary

> I built an end-to-end Azure platform project around a containerized Flask application. I provisioned the Azure foundation with modular Terraform and remote state, stored images in ACR, deployed to AKS using Helm, and built GitHub Actions CI/CD using OIDC instead of stored Azure credentials. For runtime security I integrated AKS Workload Identity with Key Vault. I also enabled Container Insights, Log Analytics, KQL and Azure Monitor alerts, then simulated a bad-image deployment, diagnosed `ImagePullBackOff`, and recovered through Helm rollback.

## 2-minute walkthrough

> The project starts with a Flask incident dashboard that exposes health, version and incident endpoints. I containerized it with Docker and run it as a non-root Gunicorn process. Terraform is split into a bootstrap layer for remote state and an environment layer composed from modules for networking, NSGs, ACR, AKS, Key Vault, monitoring and Container Insights.
>
> CI runs in GitHub Actions, authenticates to Azure using OIDC, builds the image, tags it with the commit SHA and pushes it to ACR. CD is triggered only after successful CI, checks out the same SHA, verifies the image exists, gets the AKS context and deploys through Helm. The Kubernetes deployment has probes, resource requests/limits, two baseline replicas, HPA and a rolling strategy with `maxUnavailable: 0`.
>
> For secrets, I enabled AKS OIDC and Workload Identity. A Kubernetes service account federates to a user-assigned Azure managed identity that has Key Vault Secrets User access, so the application can use `DefaultAzureCredential` without storing a client secret.
>
> For monitoring, I integrated Azure Monitor Agent with Log Analytics using a DCR/DCRA, validated `KubePodInventory`, `ContainerLogV2`, `Perf` and `KubeEvents`, then created a KQL scheduled-query alert and confirmed the email action group fired. Finally, I deliberately deployed a nonexistent image tag. The new pod entered `ImagePullBackOff`, but the old replicas stayed available. I proved the tag was missing in ACR, rolled Helm back to the known-good revision and verified the health and Key Vault endpoints.

## 5-minute deep-dive structure

Use this order so the answer stays architectural rather than becoming a tool list:

```text
1. Business/technical goal
2. Application and container
3. Terraform and Azure foundation
4. AKS and Kubernetes design
5. CI/CD and immutable artifacts
6. Identity and Key Vault
7. Monitoring and alerting
8. Failure simulation and recovery
9. Improvements for production
```

## Key claims you can defend

### Why Terraform modules?

Reusable modules separate resource implementation from environment composition. The environment passes values such as names, location, subnet IDs and monitoring workspace IDs, while the modules own the Azure resource definitions. This reduces repetition and makes another environment easier to add.

### Why remote state?

Local state is tied to one workstation. Remote Azure Storage state gives a central source of truth and supports locking so concurrent Terraform operations do not silently overwrite each other.

### Why not use `latest` for Docker images?

`latest` is mutable and breaks traceability. A Git SHA identifies the exact source revision that built the image, so the running deployment can be mapped back to one commit.

### Why GitHub OIDC?

OIDC federation avoids storing a long-lived Azure client secret in GitHub. GitHub requests a short-lived identity token, Entra validates the federated subject, and Azure issues an access token with permissions controlled by RBAC.

### Authentication vs authorization?

OIDC proves who the workflow is. Azure RBAC decides what it is allowed to do. This distinction became clear when the login path worked but the service principal still required the correct resource permissions.

### Why Workload Identity?

It lets a pod use an Azure managed identity through Kubernetes service-account federation. The application does not need a cloud credential in its image, ConfigMap, Secret, or environment file.

### What does `DefaultAzureCredential` do here?

Inside AKS, it can use the environment and projected federated token injected by Workload Identity. It exchanges that identity for an Azure token and uses it to call Key Vault.

### Why ACR admin disabled?

The registry admin account is a broad static credential. Azure RBAC identities are preferable because permissions can be scoped and rotated/managed through identity instead of shared passwords.

### Why Helm after raw Kubernetes YAML?

Raw manifests are useful for learning core Kubernetes objects. Helm adds parameterization, release history, upgrades and rollback. Once Helm owns the application, I avoid managing the same Deployment with `kubectl apply` to prevent field/ownership conflicts.

### What is the HPA doing?

The HPA keeps at least two replicas and can scale up to five based on CPU utilization, with a target around 60% in this project. It changes replica count, while the Deployment/ReplicaSet still controls pod creation.

### What happens if one pod crashes?

The kubelet reports the container/pod state and the Deployment controller continuously compares desired replicas with current Ready replicas. If a pod is lost, Kubernetes creates a replacement to restore desired state.

### What does `maxUnavailable: 0` mean?

During a rolling update Kubernetes should not intentionally reduce the number of available replicas below the desired baseline. In the bad-image test, it preserved the two healthy old replicas because the new pod never became Ready.

### What does `maxSurge: 1` mean?

Kubernetes may temporarily create one additional pod above the desired replica count while performing a rolling update.

### Why did Helm fail even though the application was still serving?

Helm was waiting for the new desired Deployment revision to become Ready. The new pod could not pull its image, so the rollout never completed and Helm timed out. Existing old replicas remaining healthy does not mean the new release succeeded.

### How did you diagnose ImagePullBackOff?

I checked pod state, described the failing pod, inspected the exact image string, then queried ACR for that tag. ACR confirmed the tag did not exist, proving the failure was artifact resolution rather than application startup.

### Why rollback instead of editing the deployment directly?

A Helm release is the deployment source of truth. Rolling back preserves release history, restores the known-good chart values/manifests consistently, and avoids creating configuration drift through ad-hoc kubectl edits.

### What is DCR/DCRA?

A Data Collection Rule defines what telemetry to collect and where to send it. A Data Collection Rule Association connects that rule to the AKS resource. Both were required to complete the Container Insights path to Log Analytics.

### Why was `ama-logs` running but data missing?

The agent being healthy only proved the collector pod was running. End-to-end telemetry also required the collection rule, association and workspace destination. After adding DCR/DCRA, Kubernetes inventory and logs appeared.

### Why `ContainerLogV2` instead of `ContainerLog`?

The project enabled the current Container Insights V2 log schema. Therefore application logs were queried from `ContainerLogV2` and the older table remained empty.

### What did the alert do?

A scheduled KQL query counted application error messages over a five-minute evaluation/window period. If the count was greater than zero, Azure Monitor fired a severity-2 alert to an action group that sent an email.

### What did you test besides deployment?

I tested ACR pulls, Kubernetes self-healing, rolling updates and rollback, ConfigMap changes, HPA behavior, Workload Identity, Key Vault retrieval, Log Analytics ingestion, KQL queries, alert delivery, and a controlled failed release.

## Scenario questions

### CI succeeded but CD cannot find the image. What do you check?

1. Confirm the CD workflow uses the CI `head_sha`.
2. Check the CI build/push job completed successfully.
3. Query ACR for the exact SHA tag.
4. Verify repository/registry name and Azure subscription/context.
5. Check ACR role assignments for the workflow identity.

### Pod is Pending, not ImagePullBackOff. What is different?

A Pending pod may not have been scheduled yet. I would inspect `kubectl describe pod` for scheduler events such as insufficient CPU/memory, taints, affinity, PVC problems, quota or node state. `ImagePullBackOff` means scheduling occurred but image retrieval failed.

### Pod is Running but not Ready. What do you check?

Readiness probe results, application logs, listening port, dependency connectivity, environment variables, ConfigMaps/Secrets, and service endpoints. Running only means the container process exists; Ready means Kubernetes considers it safe to receive traffic.

### Key Vault returns 403 from the pod. What do you inspect?

Service-account annotation, workload identity pod label, projected token variables, federated identity subject/issuer, managed identity client ID, Key Vault RBAC role, Key Vault scope, and whether the application is using the intended `DefaultAzureCredential` path.

### Terraform wants to destroy an important resource. What do you do?

Do not apply. Inspect why the address changed, compare configuration/state, check module/resource renames, provider behavior, lifecycle settings and drift. If a resource was renamed in code, consider a Terraform `moved` block or controlled state migration rather than destroying/recreating it.

### CPU is high but no obvious process appears. What is your approach?

Correlate platform metrics with node/container metrics, check throttling, interrupt/system time, kernel activity, short-lived processes, container-level usage, scheduled jobs and suspicious activity. Use Azure Monitor/KQL for time correlation and OS-level tools for process/thread detail. Avoid resizing until the cause is understood unless immediate capacity protection is required.

## Strong closing answer

> The biggest thing I learned from this project is that DevOps is not just a CI/CD pipeline. The real value came from connecting infrastructure, release traceability, identity, observability and recovery. I deliberately tested failure paths, because creating resources successfully does not prove the platform is operable.

## Resume-ready bullets

- Built an end-to-end Azure application platform using Terraform, AKS, ACR, Helm, GitHub Actions, Key Vault and Azure Monitor, implementing modular IaC, remote state, SHA-based container releases and Kubernetes autoscaling.
- Implemented passwordless GitHub-to-Azure CI/CD with OIDC federation and AKS-to-Key Vault access with Workload Identity and Azure RBAC, eliminating long-lived application cloud credentials.
- Enabled AKS observability with Container Insights, Log Analytics, DCR/DCRA and KQL-based alerting; validated telemetry and email notifications through controlled tests.
- Simulated and resolved a failed AKS deployment caused by a missing ACR image tag, diagnosed `ImagePullBackOff`, preserved service availability with a zero-unavailable rolling strategy, and recovered using Helm rollback.
