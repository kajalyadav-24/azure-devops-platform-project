module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

module "network" {
  source = "../../modules/network"

  vnet_name           = var.vnet_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  address_space       = var.vnet_address_space
  subnets             = var.subnets

  tags = var.tags
}
module "aks_nsg" {
  source = "../../modules/nsg"

  nsg_name            = "nsg-aks-dev"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.network.subnet_ids["snet-aks-dev"]

  security_rules = {}

  tags = var.tags
}

module "app_nsg" {
  source = "../../modules/nsg"

  nsg_name            = "nsg-app-dev"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.network.subnet_ids["snet-app-dev"]

  security_rules = {
    allow_http_from_vnet = {
      name                       = "Allow-HTTP-From-VNet"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    }

    allow_https_from_vnet = {
      name                       = "Allow-HTTPS-From-VNet"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    }
  }

  tags = var.tags
}
module "acr" {
  source = "../../modules/acr"

  acr_name_prefix     = var.acr_name_prefix
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku

  tags = var.tags
}
module "aks" {
  source = "../../modules/aks"

  cluster_name        = var.aks_cluster_name
  dns_prefix          = var.aks_dns_prefix
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name

  aks_subnet_id = module.network.subnet_ids["snet-aks-dev"]

  acr_id = module.acr.acr_id

  node_vm_size               = var.aks_node_vm_size
  node_count                 = var.aks_node_count
  log_analytics_workspace_id = module.monitoring.workspace_id


  tags = var.tags
}
data "azurerm_client_config" "current" {}

module "key_vault" {
  source = "../../modules/key-vault"

  name_prefix = "kv-cloudops-dev"

  location            = module.resource_group.location
  resource_group_name = module.resource_group.name

  tenant_id = data.azurerm_client_config.current.tenant_id

  workload_identity_name = "id-incident-app-dev"

  oidc_issuer_url = module.aks.oidc_issuer_url

  kubernetes_namespace = "cloudops-dev"
  service_account_name = "incident-app"

  tags = var.tags
}
module "monitoring" {
  source = "../../modules/monitoring"

  workspace_name      = "law-cloudops-dev"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name

  retention_in_days = 30

  alert_email = var.alert_email

  tags = var.tags
}

module "container_insights" {
  source = "../../modules/container-insights"

  cluster_name        = "aks-cloudops-dev"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  log_analytics_workspace_id = module.monitoring.workspace_id

  tags = var.tags

  depends_on = [
    module.aks
  ]
}