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

## Migration Steps

### Set Environment Variables

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

### Import objects into the target workspace

COMING SOON