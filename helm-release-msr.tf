
# Create Secret token to allow access to Software AG Containers Registry
resource "kubernetes_secret" "sag-registry-credentials" {
  count      =  var.deployMicroservicesRuntime ? 1 : 0

  metadata {
    name      = "sag-registry-credentials"
    namespace = "default"
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "sagcr.azurecr.io" = {
          "username" = var.dockerRegistryUsername
          "password" = var.dockerRegistryPassword
          "auth"     = base64encode("${var.dockerRegistryUsername}:${var.dockerRegistryPassword}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}

# Create Config Map for License key
resource "kubernetes_config_map" "microservicesruntime-license-key" {
  count      =  var.deployMicroservicesRuntime ? 1 : 0

  metadata {
    name = "microservicesruntime-license-key"
  }

  data = {
    "licenseKey.xml" = "${file("${var.licenseFileMicroservicesRuntime}")}"
  }
}

# Deploy Microservices Runtime with Helm Chart
resource "helm_release" "wm-msr" {
  count      =  var.deployMicroservicesRuntime ? 1 : 0

  name       = var.msrReleaseName
  repository = var.helmRegistryURL
  chart      = "microservicesruntime"

  set {
    name  = "imagePullSecrets"
    value = kubernetes_secret.sag-registry-credentials[0].metadata[0].name
  }
  set {
    name  = "microservicesruntime.licenseConfigMap"
    value = kubernetes_config_map.microservicesruntime-license-key[0].metadata[0].name
  }
  set {
    name  = "ingress.enabled"
    value = "true"
  }
  set {
    name  = "ingress.domain"
    value = "westeurope.cloudapp.azure.com"
  }  
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "persistence.enabled"
    value = "false"
  }
# ---
  set {
    name  = "persistence.logs"
    value = "false"
  }
  set {
    name  = "persistence.packages"
    value = "false"
  }
  set {
    name  = "persistence.configs"
    value = "false"
  }
# ---
  set {
    name  = "persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.default.metadata[0].name
  }
  set {
    name  = "ingress.annotations.service\\.beta\\.kubernetes\\.io/azure-dns-label-name"
    value = "my-msr-cluster"
  }
  depends_on = [ kubernetes_manifest.crd ]
}
