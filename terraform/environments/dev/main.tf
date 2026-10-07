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