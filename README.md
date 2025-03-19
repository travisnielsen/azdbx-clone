# Azure Databricks Clone - Sample

This is a sample repo that demonstrates cloning an Azure Databricks environment using the [Terraform Provider for Databricks](https://github.com/databricks/terraform-provider-databricks/blob/main/docs/guides/experimental-exporter.md). The configuration and process included here is intended to reflect an enterprise environment.

## Reference Environment

After cloning this repo to your desktop, follow these instructions to deploy.

### Prerequisites

First, ensure you have an environment baseline to work from:

* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Terraform](https://developer.hashicorp.com/terraform/install)
* [VS Code](https://code.visualstudio.com/) with the [HashiCorp Terraform Extension](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)
* An Azure subscription with at least Contributor access

Open the `azdbx-clone` directory in VS Code and create a new file called **terraform.tfvars** under the `deployment` directory. Update the contents of the file as follows.

```text
subscription_id = "[your_subscription_id]"
cidr            = "10.179.0.0/20"
```

Be sure to replace the value of `subscription_id` to match your environment.

### Deployment and Teardown

Open a new terminal in VS Code and enter the `az login` command to authenticate to your Azure environment. Be sure to select the subscription you with to work with.

Next, switch to the `deployments` directory in the terminal and run: `terraform init`.

Assuming there are no issues, run the `terraform plan` and `terraform apply` commands to deploy the environment.

> NOTE: Once you are finished with the environment, you can run the `terraform destroy` command to remove it.
