# ---------------------------------------------------------
# User Assigned Managed Identity for AKS
# ---------------------------------------------------------
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.cluster_name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}


# ---------------------------------------------------------
# Allow AKS identity to manage networking in AKS subnet
# ---------------------------------------------------------
resource "azurerm_role_assignment" "network_contributor" {
  scope                = var.aks_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}


# ---------------------------------------------------------
# AKS Cluster
# ---------------------------------------------------------
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  sku_tier = "Free"

  # -------------------------------------------------------
  # Kubernetes RBAC
  # -------------------------------------------------------
  role_based_access_control_enabled = true


  # -------------------------------------------------------
  # OIDC + Workload Identity
  #
  # Used for passwordless Pod -> Azure authentication
  # Example: AKS Pod -> Azure Key Vault
  # -------------------------------------------------------
  oidc_issuer_enabled       = true
  workload_identity_enabled = true


  # -------------------------------------------------------
  # AKS Control Plane Identity
  # -------------------------------------------------------
  identity {
    type = "UserAssigned"

    identity_ids = [
      azurerm_user_assigned_identity.aks.id
    ]
  }


  # -------------------------------------------------------
  # System Node Pool
  # -------------------------------------------------------
  default_node_pool {
    name = "system"

    node_count = var.node_count
    vm_size    = var.node_vm_size

    vnet_subnet_id = var.aks_subnet_id

    type = "VirtualMachineScaleSets"

    os_disk_size_gb = 64

    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }


  # -------------------------------------------------------
  # AKS Networking
  # -------------------------------------------------------
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"

    load_balancer_sku = "standard"

    service_cidr   = "10.0.0.0/16"
    dns_service_ip = "10.0.0.10"

    pod_cidr = "10.244.0.0/16"
  }


  # -------------------------------------------------------
  # Azure Monitor / Container Insights
  #
  # AKS telemetry -> Log Analytics Workspace
  # Uses managed identity authentication
  # -------------------------------------------------------
  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }


  # -------------------------------------------------------
  # Make sure network permission exists before AKS deploys
  # -------------------------------------------------------
  depends_on = [
    azurerm_role_assignment.network_contributor
  ]


  tags = var.tags
}


# ---------------------------------------------------------
# Allow AKS kubelet identity to pull images from ACR
# ---------------------------------------------------------
resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"

  principal_id = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}