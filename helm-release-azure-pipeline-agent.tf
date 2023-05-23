
# Deploy Azure Pipeline Agent to create wM Images
#resource "helm_release" "apa" {
#  count      =  var.deployAzurePipelineAgent ? 1 : 0
#
#  name       = "azure-pipelines-agent"
#  repository = "https://emberstack.github.io/helm-charts"
#  chart      = "azure-pipelines-agent"
#
#  set {
#    name  = "pipelines.url"
#    value = "https://dev.azure.com/wM-Inno-Container"
#  }
#  set {
#    name  = "pipelines.pat.value"
#    value = ""
#  }
#  set {
#    name  = "pipelines.agent.mountDocker"
#    value = "true"
#  }
#  set {
#    name  = "pipelines.pool"
#    value = "wm-image-creator"
#  }
#}
