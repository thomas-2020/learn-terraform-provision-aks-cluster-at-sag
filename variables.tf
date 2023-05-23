
variable "subscriptionId" {
  description = "Your Azure Subscription ID"
}

variable "clusterName" {
  description = "Name of Kubernetes Cluster"
}

variable "deployMicroservicesRuntime" {
  type        = bool
  description = "Type 'true' or 'false' to install Microservices Runtime"
}

variable "dockerRegistryUsername" {
  type        = string
  description = "Software AG Containers Registry username"
}

variable "dockerRegistryPassword" {
  type        = string
  description = "Software AG Containers Registry token/password"
}

variable "helmRegistryURL" {
  type        = string
  description = "Helm Charts Registry URL for Microservices Runtime"
}

variable "licenseFileMicroservicesRuntime" {
  type        = string
  description = "Path + Filename of Microservices Runtime License File"
}

variable "msrReleaseName" {
  type        = string
  description = "Deployed Microservices Runtime release name"
}