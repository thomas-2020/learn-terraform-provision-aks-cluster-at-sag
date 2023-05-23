
# Create all resources to start and stop AKS via automation account and runbook

resource "azurerm_automation_account" "auto_account" {
  name                    = "AKS-start-stop-Auto-Account-${var.clusterName}"
  location                = azurerm_resource_group.default.location
  resource_group_name     = azurerm_kubernetes_cluster.default.node_resource_group
  sku_name                = "Basic"
  identity {
    type                  = "SystemAssigned"
  }
}

resource "azurerm_automation_runbook" "auto_runbook" {
  name                    = "AKS-start-stop-${var.clusterName}"
  location                = azurerm_resource_group.default.location
  resource_group_name     = azurerm_kubernetes_cluster.default.node_resource_group
  automation_account_name = azurerm_automation_account.auto_account.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "Start or Stop AKS via scheduled runbook script"
  runbook_type            = "PowerShell"
  content                 = data.local_file.aks-start-stop.content
}

data "local_file" "aks-start-stop" {
  filename = "aks-start-stop.ps1"
}

locals {
  tomorrow = formatdate( "YYYY-MM-DD", timeadd( timestamp(), "24h" ) )
}

resource "azurerm_automation_schedule" "schedule-stop" {
  name                    = "stop-${var.clusterName}-${var.clusterName}"
  resource_group_name     = azurerm_kubernetes_cluster.default.node_resource_group
  automation_account_name = azurerm_automation_account.auto_account.name
  frequency               = "Week"
  timezone                = "UTC"
  description             = "Stop AKS cluster every week day at 18:00"
  week_days               = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" ]
  start_time              = "${local.tomorrow}T18:00:00+01:00" 
}

resource "azurerm_automation_job_schedule" "job-stop" {
  resource_group_name     = azurerm_kubernetes_cluster.default.node_resource_group
  automation_account_name = azurerm_automation_account.auto_account.name
  schedule_name           = azurerm_automation_schedule.schedule-stop.name
  runbook_name            = azurerm_automation_runbook.auto_runbook.name

  parameters = {
    aksclustername        = "${var.clusterName}"
    resourcegroupname     = azurerm_resource_group.default.name
    operation             = "Stop"
    subscriptionid        = "${var.subscriptionId}"
  }
}

# Attaching AKS to Automation Account to get start/stop permissions ...
resource "azurerm_role_assignment" "AKS-to-AA" {
  principal_id                     = azurerm_automation_account.auto_account.identity[0].principal_id
  role_definition_name             = "Contributor"
  scope                            =  azurerm_kubernetes_cluster.default.id
  skip_service_principal_aad_check = true
}
