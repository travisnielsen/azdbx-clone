# Azure Databricks Clone - Sample

This is a sample repo that demonstrates cloning an Azure Databricks environment using the [Terraform Provider for Databricks](https://github.com/databricks/terraform-provider-databricks/blob/main/docs/guides/experimental-exporter.md). The configuration and process included here is intended to reflect an enterprise environment.

## Reference Environment

After cloning this repo to your desktop, follow these instructions to deploy.

### Prerequisites

This guide assumes a workstation running Ubuntu 24.04LTS via Windows Subsystem for Linux. First, ensure you have an environment baseline to work from:

* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Databricks CLI](https://docs.databricks.com/aws/en/dev-tools/cli/install#curl-install)
* [Terraform](https://developer.hashicorp.com/terraform/install)
* [VS Code](https://code.visualstudio.com/) with the [HashiCorp Terraform Extension](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)
* An Azure subscription with at least Contributor access

Open the `azdbx-clone` directory in VS Code and create a new file called **terraform.tfvars** under the [source](/source/) directory. Update the contents of the file as follows:

```text
subscription_id = "[your_subscription_id]"
cidr            = "10.179.0.0/20"
```

Switch to the [target](/target/) directory and create a **terraform.tfvars** file. Update the contents of the file as follows:

```text
subscription_id = "[your_subscription_id]"
cidr            = "10.180.0.0/20"
```

In each file, be sure to replace the value of `subscription_id` to match your environment.

### Deployment and Teardown

Open a new terminal in VS Code and enter the `az login` command to authenticate to your Azure environment. Be sure to select the subscription you with to work with.

Next, switch to the `source` directory in the terminal and run: `terraform init`.

Assuming there are no issues, run the `terraform plan` and `terraform apply` commands to deploy the environment.

Repeat this process by running the above commands from the `target` directory.

> NOTE: Once you are finished with the environment, you can run the `terraform destroy` command to remove it.

## Export

### Set environment variables

Follow these [instructions to createa a Personal Access Token](https://docs.databricks.com/aws/en/dev-tools/auth/pat#databricks-personal-access-tokens-for-workspace-users) (PAT) in the source workspace. Next, set the following environment variables:

```bash
export DATABRICKS_HOST=[your_workspace_url]
export DATABRICKS_TOKEN=[your_PAT]
```

### Export the source workspace objects

Next navigate to the `source` director and locate the file named `terraform-provider-databricks_v1.70.0` within `.terraform/providers/registry.terraform.io/databricks/1.70.0/linux_amd64`. The exact path may vary slightly depending on your workstation build. Copy the file to the project root directory and run the utility:

```bash
./terraform-provider-databricks_v1.70.0 exporter -directory=export-workspace -export-secrets -mounts -skip-interactive
```

## Import

### Prepare files

Before performing the import to the new workspace, some files within the `export-` directory must first be updated. Start by adding the following to `vars.tf`:

```terraform
variable "string_value_demo_admin_token_484725b503" {
  description = ""
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID to deploy the workspace into"
}

variable "workspace_host_url" {
  type        = string
  description = "Databricks workspace URL"
}
```

Replace the contents of `databricks.tf` with the following:

```terraform
terraform {
  required_providers {
    azurerm = "~> 4.0"
    databricks = {
      source  = "databricks/databricks"
      version = "1.70.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
provider "databricks" {
    host = var.workspace_host_url
}
```

Update the `terraform.tfvars` file with the following variables:

```bash
subscription_id = "[target_subscription_id]"
workspace_host_url = "[target_workspace_url]"
```

### Apply configuration to the target workspace

Standard Terraform commands are used for this step. In a terminal, switch to the export directory and run the following:

```bash
terraform init
terraform plan
terraform apply
```