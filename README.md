# Learn Terraform - How to provision Azure Kubernetes Service Cluster @ Software AG Environment

This tutorial is cloned from [Terraform provision an AKS Cluster tutorial](https://developer.hashicorp.com/terraform/tutorials/kubernetes/aks) and extended for use in Software AG environment.

At the end of the tutorial, you have provisioned a Kubernetes Service in Azure (AKS) by using Terraform.

## Why deploy with Terraform?

While you could use the built-in Azure provisioning processes (UI, CLI) for AKS clusters, Terraform provides you with several benefits:

* **Unified Workflow** - If you are already deploying infrastructure to Azure with Terraform, your AKS cluster can fit into that workflow. You can also deploy applications into your AKS cluster using Terraform.

* **Full Lifecycle Management** - Terraform doesn't only create resources, it updates, and deletes tracked resources without requiring you to inspect the API to identify those resources.

* **Graph of Relationships** - Terraform understands dependency relationships between resources. For example, an Azure Kubernetes cluster needs to be associated with a resource group, Terraform won't attempt to create the cluster if the resource group failed to create.

## Prerequisites

To create resources in Azure, you need a subscription. You can use your Visual Studio Professional Subscription. Furthermore, we need following installed software from Company Portal ...

* Terraform
* Microsoft Azure CLI

This combination is currently available only on Windows. Therefore, we can run only this OS.

To access the AKS, install from Company Portal ...

* kubectl

## Provisioning

### Clone Repository

Clone Git repository [https://github.com/thomas-2020/learn-terraform-provision-aks-cluster-at-sag](https://github.com/thomas-2020/learn-terraform-provision-aks-cluster-at-sag)

```
git clone https://github.com/thomas-2020/learn-terraform-provision-aks-cluster-at-sag.git
```

### Start Command Line

Start new command prompt after software installation. The commands `terraform` and `az` should be available. Go to sub-directory of cloned repository with your command shell.

### Initialize Terraform

Initialize Terraform: `terraform init`. You should get the output ...

```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "2.66.0"...
- Installing hashicorp/azurerm v2.66.0...
- Installed hashicorp/azurerm v2.66.0 (signed by HashiCorp)
```

### Login to Azure

Login to your Azure account: `az login`. This command (typed in command prompt) starts the login into your default browser. After successfully login, you will find the subscription ID in the terminal window ...

```
...
    "cloudName": "AzureCloud",
    "homeTenantId": "d9662eb9-ad98-4e74-a8a2-04ed5d544db6",
    "id": "e465eb8e-cc28-4320-ae78-892a9a06bcbe",
    "isDefault": true,
    "managedByTenants": [],
    "name": "Visual Studio Professional Subscription",
...
```

Copy/past the ID in field `id` (of the subscription which you want to use) to  `terraform.tfvars` ...

```
subscriptionId =  "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxxxxxxx"
```

### Start Provisioning

Start provisioning with Terraform: `terraform apply`. After input validation, Terraform prints following output ...

```
...
Plan: 4 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + kubernetes_cluster_name = "MyCluster"
  + resource_group_name     = "MyCluster-rg"

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

Enter `yes` to start the provisioning. For changing the cluster name `MyCluster`, there are 2 possibilities ...

* set another name on changing the property in `terraform.tfvars` or
* overwrite properties with `terraform apply -var clusterName=FirstTestCluster`

**Note:** You can use in this tutorial only alphanumeric characters as cluster name because a container registry is also created with this name. The container registry name can have only alphanumeric characters.

### Configure kubectl

Now that you've provisioned your AKS cluster, you need to configure `kubectl`. Run the following command to retrieve the access credentials for your cluster and automatically configure `kubectl`.

```
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw kubernetes_cluster_name)
```

## Using Container Registry

The provisioning creates a container registry (with cluster name) and do the attaching (role assignment) to AKS cluster. You can use [webMethods Image Creator](https://dev.azure.com/wM-Inno-Container/webmethods-image-creator) to create images and push them to registry.

## Cleanup Provisioning

With `terraform destroy` you can delete all resources (which are created during provisioning).
