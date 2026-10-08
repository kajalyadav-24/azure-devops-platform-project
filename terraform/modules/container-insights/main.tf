data "azurerm_kubernetes_cluster" "target" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_monitor_data_collection_rule" "this" {
  name                = "MSCI-${var.location}-${var.cluster_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "Linux"

  destinations {
    log_analytics {
      name                  = "ciworkspace"
      workspace_resource_id = var.log_analytics_workspace_id
    }
  }

  data_flow {
    streams = [
      "Microsoft-ContainerInsights-Group-Default"
    ]

    destinations = [
      "ciworkspace"
    ]
  }

  data_sources {
    extension {
      name           = "ContainerInsightsExtension"
      extension_name = "ContainerInsights"

      streams = [
        "Microsoft-ContainerInsights-Group-Default"
      ]

      extension_json = jsonencode({
        dataCollectionSettings = {
          interval               = "1m"
          namespaceFilteringMode = "Off"
          enableContainerLogV2   = true
        }
      })
    }
  }

  description = "DCR for AKS Container Insights"

  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule_association" "this" {
  name                    = "ContainerInsightsExtension"
  target_resource_id      = data.azurerm_kubernetes_cluster.target.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.this.id

  description = "Associates AKS with the Container Insights data collection rule."
}