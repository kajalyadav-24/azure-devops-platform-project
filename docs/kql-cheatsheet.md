# KQL Cheatsheet

These queries are aligned with the AKS / Container Insights implementation used by this project.

## Pod health

```kusto
KubePodInventory
| where TimeGenerated > ago(30m)
| where Namespace == "cloudops-dev"
| where Name contains "incident-app"
| project TimeGenerated, Name, PodStatus, ContainerStatus, PodRestartCount
| order by TimeGenerated desc
```

## Restarting pods

```kusto
KubePodInventory
| where TimeGenerated > ago(1h)
| where Namespace == "cloudops-dev"
| where PodRestartCount > 0
| summarize MaxRestarts=max(PodRestartCount) by Name
| order by MaxRestarts desc
```

## Application errors

```kusto
ContainerLogV2
| where TimeGenerated > ago(30m)
| where PodNamespace == "cloudops-dev"
| where ContainerName == "incident-app"
| where LogMessage has_any ("ERROR", "Exception", "Failed", "Forbidden", "Traceback")
| project TimeGenerated, PodName, LogMessage
| order by TimeGenerated desc
```

## Key Vault / identity activity

```kusto
ContainerLogV2
| where TimeGenerated > ago(1h)
| where PodNamespace == "cloudops-dev"
| where ContainerName == "incident-app"
| where LogMessage has_any ("Key Vault", "WorkloadIdentityCredential", "DefaultAzureCredential", "vault.azure.net")
| project TimeGenerated, PodName, LogMessage
| order by TimeGenerated desc
```

## Kubernetes failures and backoff events

```kusto
KubeEvents
| where TimeGenerated > ago(1h)
| where Namespace == "cloudops-dev"
| where Reason in ("Failed", "BackOff")
    or Message has_any ("ImagePullBackOff", "ErrImagePull", "CrashLoopBackOff")
| project TimeGenerated, Name, Reason, Message
| order by TimeGenerated desc
```

## Container CPU in millicores

```kusto
Perf
| where TimeGenerated > ago(30m)
| where ObjectName == "K8SContainer"
| where CounterName == "cpuUsageNanoCores"
| extend CPU_millicores = CounterValue / 1000000.0
| project TimeGenerated, InstanceName, CPU_millicores
| order by TimeGenerated desc
```

## Container memory in MiB

```kusto
Perf
| where TimeGenerated > ago(30m)
| where ObjectName == "K8SContainer"
| where CounterName == "memoryWorkingSetBytes"
| extend Memory_MiB = CounterValue / 1024.0 / 1024.0
| project TimeGenerated, InstanceName, Memory_MiB
| order by TimeGenerated desc
```

## Node inventory

```kusto
KubeNodeInventory
| where TimeGenerated > ago(30m)
| summarize arg_max(TimeGenerated, *) by Computer
| project TimeGenerated, Computer, Status, KubeletVersion, OperatingSystem
```

## Node CPU

```kusto
Perf
| where TimeGenerated > ago(30m)
| where ObjectName == "K8SNode"
| where CounterName contains "cpu"
| project TimeGenerated, Computer, CounterName, CounterValue
| order by TimeGenerated desc
```

## Node memory

```kusto
Perf
| where TimeGenerated > ago(30m)
| where ObjectName == "K8SNode"
| where CounterName contains "memory"
| project TimeGenerated, Computer, CounterName, CounterValue
| order by TimeGenerated desc
```

## Errors by five-minute window

```kusto
ContainerLogV2
| where TimeGenerated > ago(1h)
| where PodNamespace == "cloudops-dev"
| where ContainerName == "incident-app"
| where LogMessage has_any ("ERROR", "Exception", "Failed", "Forbidden", "Traceback")
| summarize ErrorCount=count() by bin(TimeGenerated, 5m)
| order by TimeGenerated asc
```

## Interview points

- `KubePodInventory` is useful for pod status and restart history.
- `ContainerLogV2` is the current container log table used in this implementation.
- `Perf` stores performance counters, so unit conversion is often required.
- `KubeEvents` helps diagnose scheduler, image-pull and lifecycle failures that may occur before application logs exist.
- KQL is valuable because troubleshooting should correlate workload state, events, logs, and metrics instead of using only one signal.
