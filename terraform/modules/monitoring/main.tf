# ---------------------------------------------------------
# Log Analytics Workspace
# ---------------------------------------------------------
resource "azurerm_log_analytics_workspace" "this" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku               = "PerGB2018"
  retention_in_days = var.retention_in_days

  tags = var.tags
}


# ---------------------------------------------------------
# Azure Monitor Action Group
# Used to send alert notifications
# ---------------------------------------------------------
resource "azurerm_monitor_action_group" "cloudops" {
  name                = "ag-cloudops-dev"
  resource_group_name = var.resource_group_name
  short_name          = "cloudops"

  email_receiver {
    name                    = "primary-email"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  tags = var.tags
}


# ---------------------------------------------------------
# Azure Monitor Scheduled Query Alert
# Detect application errors from ContainerLogV2
# ---------------------------------------------------------
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "incident_app_errors" {
  name                = "alert-incident-app-errors"
  resource_group_name = var.resource_group_name
  location            = var.location

  display_name = "Incident App - Application Errors"

  description = "Triggers when error-like log messages are detected for incident-app in cloudops-dev."

  scopes = [
    azurerm_log_analytics_workspace.this.id
  ]

  severity = 2
  enabled  = true

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  criteria {
    query = <<-QUERY
      ContainerLogV2
      | where PodNamespace == "cloudops-dev"
      | where ContainerName == "incident-app"
      | where LogMessage has_any (
          "ERROR",
          "Exception",
          "Failed",
          "Forbidden",
          "Traceback"
        )
    QUERY

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  # -------------------------------------------------------
  # When alert fires -> send notification through
  # Azure Monitor Action Group
  # -------------------------------------------------------
  action {
    action_groups = [
      azurerm_monitor_action_group.cloudops.id
    ]
  }

  auto_mitigation_enabled = true

  tags = var.tags
}