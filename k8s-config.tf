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
    name      = "azure-storage-account-${azurerm_storage_account.default.name}-secret"
    namespace = "default"
  }

  data = {
      azurestorageaccountname = azurerm_storage_account.default.name
      azurestorageaccountkey  = azurerm_storage_account.default.primary_access_key
  }

  type = "Opaque"
}

# Use another Storage account
resource "kubernetes_secret" "myakstest" {

  metadata {
    name      = "azure-storage-account-myakstest-secret"
    namespace = "default"
  }

  data = {
      azurestorageaccountname = "myakstest"
      azurestorageaccountkey  = "6/cSrHqehtcht5KG/dtajpSBrfFYLsmTw6XZEeUP4+PnuiwU5TJJhsL+x9xuBeMBK0+YUT7z64Ub+ASt+GT4LQ=="
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
    storage_class_name               = "azureblob-nfs-premium"
#    storage_class_name               = "azureblob-fuse-premium"
#    mount_options                    = [ "-o allow_other", "--file-cache-timeout-in-seconds=120" ] 

	persistent_volume_source {
      csi {
        driver            = "blob.csi.azure.com"
        read_only         = "false"

#       ResourceGroup StorageAccount_Name Container_Name
        volume_handle     = "MC_MyCluster-rg_MyCluster_westeurope#myclusterstorage#msr-pv"
#        volume_handle     = "MC_MyCluster-rg_MyCluster_westeurope#myakstest#msr-pv"
        volume_attributes = {
          resource_group  = azurerm_kubernetes_cluster.default.node_resource_group
          storage_account = azurerm_storage_account.default.name
#          storage_account = "myakstest"
          container_name  = azurerm_storage_container.default.name
          protocol        = "nfs"
        }
        node_stage_secret_ref {
          name            = kubernetes_secret.default.metadata[0].name
#          name            = kubernetes_secret.myakstest.metadata[0].name
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
#    storage_class_name = "azureblob-fuse-premium" 
    storage_class_name = "azureblob-nfs-premium"
  }
}

# Pull manifests for Service Monitor / CRD ...
data "http" "crd" {
  url = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml"
}

# Deploy Service Monitor / CRD ...
resource "kubernetes_manifest" "crd" {
  for_each = {
    for value in [
      for yaml in split(
        "\n---\n",
        "\n${replace(data.http.crd.body, "/(?m)^---[[:blank:]]*(#.*)?$/", "---")}\n"
      ) :
      yamldecode(yaml)
      if trimspace(replace(yaml, "/(?m)(^[[:blank:]]*(#.*)?$)+/", "")) != ""
    ] : "${value["kind"]}--${value["metadata"]["name"]}" => value
  }
  manifest = each.value
}