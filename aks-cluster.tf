
provider "azurerm" {
  features {}

  subscription_id = "${var.subscriptionId}"
}

resource "azurerm_resource_group" "default" {
  name     = "${var.clusterName}-rg"
  location = "West Europe"

  tags = {
    environment = "Demo"
  }
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = "${var.clusterName}"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${var.clusterName}-k8s"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_B2s"
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }


  role_based_access_control {
    enabled = true
  }

  tags = {
    environment = "Demo"
  }


  addon_profile {
    http_application_routing {
      enabled = true
    }
  }
  
}

/* https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry */
/* Create Container Registry ... */
resource "azurerm_container_registry" "acr" {
  name                = "${var.clusterName}Registry"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    environment = "Demo"
  }
}

# Attaching Container Registry to K8S Cluster ...
resource "azurerm_role_assignment" "default" {
  principal_id                     = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# Create Azure Storage account for PVC
resource "azurerm_storage_account" "default" {
  name                     = lower( "${var.clusterName}Storage" )
#  resource_group_name      = azurerm_resource_group.default.name
  resource_group_name      = azurerm_kubernetes_cluster.default.node_resource_group
  location                 = azurerm_resource_group.default.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = "true"
}

# Create Storage container inside Storage account to stop Microservices Runtime data
resource "azurerm_storage_container" "default" {
  name                  = "msr-pv"
  storage_account_name  = azurerm_storage_account.default.name
  container_access_type = "private"
}

# Not needed ...
# Create Disk for mounting in Pod/Persistent Volume
#resource "azurerm_managed_disk" "disk" {
#  name                 = "msr-disk"
#  location             = azurerm_resource_group.default.location
#  resource_group_name  = azurerm_resource_group.default.name
#  storage_account_type = "Standard_LRS"
#  create_option        = "Empty"
#  disk_size_gb         = "1"
#}