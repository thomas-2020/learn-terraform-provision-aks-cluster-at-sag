#
# This module does Kubernetes configuration settings after provisioning
#

# Create unique ID for volumume
resource "random_pet" "volume" {}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.default.kube_config.0.host

  client_certificate     = base64decode( azurerm_kubernetes_cluster.default.kube_config.0.client_certificate )
  client_key             = base64decode( azurerm_kubernetes_cluster.default.kube_config.0.client_key )
  cluster_ca_certificate = base64decode( azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate )
}

# Create Secret token to allow access from PVC to Azure storage account
resource "kubernetes_secret" "default" {

  metadata {
    name      = "myclusterstorage-secret"
    namespace = "default"
  }

  data = {
      azurestorageaccountname = azurerm_storage_account.default.name
      azurestorageaccountkey  = azurerm_storage_account.default.primary_access_key
  }

  type = "Opaque"
}

# Create PV
resource "kubernetes_persistent_volume" "default" {
  metadata {
    name      = "msr-pv"
  }
  
  spec {
    capacity = {
      storage = "10M"
    }
    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"  # If set as "Delete" container would be removed after pvc deletion
    storage_class_name               = "azureblob-fuse-premium"
    mount_options                    = [ "-o allow_other", "--file-cache-timeout-in-seconds=120" ] 

	persistent_volume_source {
      csi {
        driver            = "blob.csi.azure.com"
        read_only         = "false"

        volume_handle     = "${random_pet.volume.id}"
        volume_attributes = {
          container_name  = azurerm_storage_container.default.name
        }
        node_stage_secret_ref {
          name            = kubernetes_secret.default.metadata[0].name
          namespace       = "default"
        }
      }      
    }
  }
}

# Create PVC
resource "kubernetes_persistent_volume_claim" "default" {
  metadata {
    name               = "msr-pvc"
  }
  spec {
    access_modes       = [ "ReadWriteMany" ]
    resources {
      requests         = {
        storage        = "10M"
      }
    }
    volume_name        = kubernetes_persistent_volume.default.metadata[0].name
    storage_class_name = "azureblob-fuse-premium" 
  }
}
