terraform {
  required_providers {
    azurerm = "~> 4.0"
    random  = "~> 3.6"
    databricks = {
      source = "databricks/databricks"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "databricks" {
    host = azurerm_databricks_workspace.this.workspace_url
}
