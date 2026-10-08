# Operations Runbook

This runbook contains the day-2 commands used to operate and troubleshoot the development platform. Commands assume Windows PowerShell.

## 1. Set common context

```powershell
$RG = "rg-cloudops-dev"
$AKS = "aks-cloudops-dev"
$ACR = "acrcloudopsdevw9yni0"
$NS = "cloudops-dev"
$APP = "incident-app"
```

Avoid storing tenant IDs, subscription IDs, passwords, or secret values in scripts committed to Git.

## 2. Azure login and subscription

```powershell
az login
az account show --output table
```

If multiple subscriptions are available:

```powershell
az account set --subscription "<subscription-id-or-name>"
```

## 3. Get AKS credentials

```powershell
az aks get-credentials `
  --resource-group $RG `
  --name $AKS `
  --overwrite-existing
```

Validate connectivity:

```powershell
kubectl get nodes -o wide
kubectl get pods -A
```

## 4. Application health

```powershell
kubectl get deployment $APP -n $NS
kubectl get pods -n $NS -o wide
kubectl get svc -n $NS
```

Rollout status:

```powershell
kubectl rollout status deployment/$APP -n $NS --timeout=180s
```

Current deployed image:

```powershell
kubectl get deployment $APP `
  -n $NS `
  -o jsonpath="{.spec.template.spec.containers[0].image}"
```

## 5. Application endpoint validation

Start a local port-forward:

```powershell
kubectl port-forward deployment/$APP 18080:8080 -n $NS
```

From another PowerShell terminal:

```powershell
curl.exe http://localhost:18080/health
curl.exe http://localhost:18080/version
curl.exe http://localhost:18080/api/keyvault-check
```

Expected Key Vault validation shape:

```json
{
  "authentication": "AKS Workload Identity",
  "key_vault_access": true,
  "secret_loaded": true,
  "status": "success"
}
```

The endpoint must never return the secret value.

## 6. Pod logs and events

Application logs:

```powershell
kubectl logs -n $NS deployment/$APP --tail=200
```

Single pod:

```powershell
kubectl logs -n $NS <pod-name> --tail=200
```

Describe a failing pod:

```powershell
kubectl describe pod <pod-name> -n $NS
```

Recent Kubernetes events:

```powershell
kubectl get events -n $NS --sort-by=.lastTimestamp
```

## 7. Diagnose ImagePullBackOff

Check the pod and image:

```powershell
kubectl get pods -n $NS
kubectl get pod <pod-name> -n $NS -o jsonpath="{.spec.containers[0].image}"
kubectl describe pod <pod-name> -n $NS
```

Check ACR tags:

```powershell
az acr repository show-tags `
  --name $ACR `
  --repository incident-app `
  --orderby time_desc `
  --output table
```

Check one exact image:

```powershell
az acr repository show `
  --name $ACR `
  --image "incident-app:<tag>" `
  --output table
```

If ACR returns that the tag does not exist, the release is pointing to an artifact that was never pushed or is using the wrong tag.

## 8. Helm operations

Lint:

```powershell
helm lint .\helm\incident-app
```

List release:

```powershell
helm list -n $NS
```

History:

```powershell
helm history $APP -n $NS
```

Inspect values:

```powershell
helm get values $APP -n $NS
```

Inspect rendered manifest from deployed release:

```powershell
helm get manifest $APP -n $NS
```

Rollback:

```powershell
helm rollback $APP <known-good-revision> `
  --namespace $NS `
  --wait `
  --timeout 5m
```

After rollback, always verify the image, pod state, health endpoint, and dependent services such as Key Vault.

## 9. Workload Identity checks

Service account:

```powershell
kubectl get serviceaccount incident-app -n $NS -o yaml
```

Pod workload identity label:

```powershell
kubectl get deployment $APP -n $NS `
  -o jsonpath="{.spec.template.metadata.labels.azure\.workload\.identity/use}"
```

Identity-related environment variables inside a pod:

```powershell
$POD = kubectl get pod -n $NS -l app=incident-app -o jsonpath="{.items[0].metadata.name}"
kubectl exec -n $NS $POD -- env | Select-String "AZURE_"
```

Useful variables injected by Workload Identity include `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_FEDERATED_TOKEN_FILE`.

## 10. Terraform operations

Bootstrap layer:

```powershell
cd terraform\bootstrap
terraform fmt
terraform init
terraform validate
terraform plan
```

Environment layer:

```powershell
cd terraform\environments\dev
terraform fmt -recursive
terraform init
terraform validate
terraform plan
```

Before apply, inspect the full plan and confirm unexpected destroy/replace actions are absent.

Apply:

```powershell
terraform apply
```

Final consistency check:

```powershell
terraform plan
```

Expected after successful convergence:

```text
No changes. Your infrastructure matches the configuration.
```

## 11. Terraform state checks

List state:

```powershell
terraform state list
```

Inspect one object:

```powershell
terraform state show <resource-address>
```

Do not manually edit state unless there is a specific recovery requirement and a backup exists.

## 12. AKS quota troubleshooting

Check regional compute quota:

```powershell
az vm list-usage `
  --location centralindia `
  --output table
```

A node-pool deployment can fail even when total regional quota exists if the requested VM family has no quota. Validate the exact VM family, not only total vCPU quota.

## 13. Container Insights validation

Agent pods:

```powershell
kubectl get pods -n kube-system | Select-String "ama-logs"
```

AKS monitoring addon:

```powershell
az aks show `
  --resource-group $RG `
  --name $AKS `
  --query addonProfiles.omsagent
```

DCR association:

```powershell
az monitor data-collection rule association list `
  --resource $AKS `
  --resource-group $RG `
  --resource-type Microsoft.ContainerService/managedClusters `
  --output table
```

## 14. Common KQL checks

Pod state:

```kusto
KubePodInventory
| where TimeGenerated > ago(30m)
| where Namespace == "cloudops-dev"
| where Name contains "incident-app"
| project TimeGenerated, Name, PodStatus, ContainerStatus, PodRestartCount
| order by TimeGenerated desc
```

Application errors:

```kusto
ContainerLogV2
| where TimeGenerated > ago(30m)
| where PodNamespace == "cloudops-dev"
| where ContainerName == "incident-app"
| where LogMessage has_any ("ERROR", "Exception", "Failed", "Forbidden", "Traceback")
| project TimeGenerated, PodName, LogMessage
| order by TimeGenerated desc
```

Image pull failures:

```kusto
KubeEvents
| where TimeGenerated > ago(1h)
| where Namespace == "cloudops-dev"
| where Reason in ("Failed", "BackOff") or Message has "ImagePull"
| project TimeGenerated, Name, Reason, Message
| order by TimeGenerated desc
```

## 15. Alert validation

Action group:

```powershell
az monitor action-group list `
  --resource-group $RG `
  --output table
```

Scheduled query rules:

```powershell
az monitor scheduled-query list `
  --resource-group $RG `
  --output table
```

Alert tests should be controlled, temporary, and removed immediately after validation.

## 16. Git/repository final checks

```powershell
git status
git diff --check
git ls-files | Select-String "\.venv|\.terraform/|terraform\.tfstate|tfplan|drift\.tfplan|__pycache__"
```

The forbidden-file check should return nothing.

Run the included repository health script:

```powershell
.\scripts\repo-health-check.ps1
```

## 17. Incident response order

When a release fails, use this sequence:

```text
1. Confirm user impact and current availability.
2. Check deployment/pod state.
3. Check rollout history and current image.
4. Read pod events and logs.
5. Verify external dependency/artifact state.
6. Identify the last known-good Helm revision.
7. Roll back if faster/safer than forward-fixing.
8. Validate health and dependencies.
9. Check telemetry/alerts.
10. Record RCA and prevention action.
```
