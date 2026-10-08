# Incident Response and RCA

## Incident: AKS deployment stuck in ImagePullBackOff

### Summary

A controlled failure was introduced by upgrading the Helm release with a container image tag that did not exist in Azure Container Registry. The new pod could not pull its image and entered `ImagePullBackOff`. The release timed out, but the existing two replicas stayed healthy because the Deployment used `maxUnavailable: 0` and `maxSurge: 1`.

The incident was diagnosed using Kubernetes pod state/events, image inspection, and an ACR lookup. The release was recovered by rolling back to the known-good Helm revision and validating the application health and Key Vault integration.

### Severity

Training / controlled incident. No production customer impact.

### Detection

The Helm upgrade returned:

```text
UPGRADE FAILED: resource not ready, name: incident-app,
kind: Deployment, status: InProgress
context deadline exceeded
```

`kubectl get pods` showed one new pod in `ImagePullBackOff` while the previous two pods remained `Running`.

### Timeline

```text
T0   Helm upgrade started with image tag broken-image-test
T+   New ReplicaSet created
T+   New pod attempted ACR pull
T+   Pod entered ErrImagePull / ImagePullBackOff
T+   Existing replicas remained available
T+2m Helm --wait timed out
T+   Pod image inspected
T+   ACR queried for the exact image tag
T+   ACR confirmed the tag did not exist
T+   Helm release rolled back to revision 11
T+   Rollback created deployed revision 13
T+   /health returned healthy
T+   /api/keyvault-check confirmed Workload Identity and Key Vault access
```

### Evidence

Bad image configured in the failed pod:

```text
acrcloudopsdevw9yni0.azurecr.io/incident-app:broken-image-test
```

ACR validation:

```text
Error: the specified tag does not exist.
```

Helm history after recovery:

```text
11  superseded  Upgrade complete
12  failed      Upgrade failed: deployment not ready / context deadline exceeded
13  deployed    Rollback to 11
```

### Root cause

The release referenced a nonexistent ACR image tag. Kubernetes was therefore unable to retrieve the container image for the new ReplicaSet.

```text
Invalid Helm image tag
  -> Deployment creates new ReplicaSet
  -> kubelet requests image from ACR
  -> ACR cannot resolve tag
  -> image pull fails
  -> pod cannot start
  -> readiness never succeeds
  -> Helm wait reaches timeout
```

### Why the application stayed available

The Deployment rolling strategy was:

```yaml
maxUnavailable: 0
maxSurge: 1
```

With two desired replicas, Kubernetes was allowed to create one extra pod during the rollout but was not allowed to intentionally make either healthy old replica unavailable. Because the replacement pod never became Ready, the old ReplicaSet remained serving.

This is an important distinction: the deployment **failed**, but the service did not necessarily experience an outage.

### Diagnosis commands

```powershell
kubectl get pods -n cloudops-dev -o wide
kubectl get deployment incident-app -n cloudops-dev
kubectl describe pod <bad-pod> -n cloudops-dev
kubectl get pod <bad-pod> -n cloudops-dev -o jsonpath="{.spec.containers[0].image}"
az acr repository show --name acrcloudopsdevw9yni0 --image "incident-app:broken-image-test" --output table
helm history incident-app -n cloudops-dev
```

### Recovery

Known-good release revision:

```text
11
```

Rollback:

```powershell
helm rollback incident-app 11 `
  --namespace cloudops-dev `
  --wait `
  --timeout 5m
```

Post-recovery checks:

```powershell
kubectl get pods -n cloudops-dev
kubectl rollout status deployment/incident-app -n cloudops-dev --timeout=180s
kubectl get deployment incident-app -n cloudops-dev -o jsonpath="{.spec.template.spec.containers[0].image}"
helm history incident-app -n cloudops-dev
```

Application validation:

```powershell
kubectl port-forward deployment/incident-app 18080:8080 -n cloudops-dev
curl.exe http://localhost:18080/health
curl.exe http://localhost:18080/api/keyvault-check
```

The restored version matched the known-good SHA and both endpoints succeeded.

### Prevention already present in normal CD

The controlled test deliberately bypassed safeguards that exist in the normal deployment workflow. The CD workflow:

- receives the exact CI `head_sha`,
- checks that the SHA-tagged image exists in ACR before deployment,
- uses Helm deployment protection with rollback-on-failure behavior,
- waits for the rollout,
- verifies the deployed image and pod state.

Because of these controls, a manually supplied nonexistent tag is much less likely to reach a normal automated release.

### Further production improvements

Potential hardening options:

- Admission policy requiring immutable image tags or digests.
- Container image signature verification.
- Separate deployment environments with promotion gates.
- Automated rollback on SLO/health degradation.
- Kubernetes-event alerting for repeated `ImagePullBackOff` or `CrashLoopBackOff`.
- Pod Disruption Budget for critical workloads.
- Progressive delivery/canary strategy for higher-risk services.

### Interview-ready explanation

> I simulated a failed AKS release by deploying a nonexistent ACR image tag. The new pod entered `ImagePullBackOff`, but the existing replicas stayed healthy because the rolling strategy had `maxUnavailable: 0`. I inspected the failing pod, confirmed the exact image reference, queried ACR and proved the tag did not exist. I then rolled the Helm release back to the known-good revision and validated the restored image, health endpoint, and Key Vault Workload Identity path. The main prevention is that the real CD workflow verifies the exact SHA image exists before Helm deploys it and uses rollback protection.
