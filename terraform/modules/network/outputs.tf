output "vnet_id" {
  description = "Virtual Network resource ID."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Virtual Network name."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map containing subnet names and their Azure resource IDs."

  value = {
    for subnet_name, subnet in azurerm_subnet.this :
    subnet_name => subnet.id
  }
}

output "subnet_names" {
  description = "Map containing subnet names."

  value = {
    for subnet_name, subnet in azurerm_subnet.this :
    subnet_name => subnet.name
  }
}

