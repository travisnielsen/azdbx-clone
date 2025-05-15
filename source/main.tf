locals {
  prefix = "dbxsource${random_string.naming.result}"
  tags = {
    Environment = "Demo"
    Owner       = lookup(data.external.me.result, "name")
  }
}

resource "azurerm_resource_group" "this" {
  name     = "${local.prefix}-rg"
  location = var.region
  tags     = local.tags
}

resource "azurerm_resource_group" "shared_rg" {
  name     = "${local.prefix}-shared-rg"
  location = var.region
  tags     = local.tags
}
