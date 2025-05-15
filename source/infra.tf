data "azurerm_subscription" "current" {}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

data "azurerm_client_config" "current" {
}

data "external" "me" {
  program = ["az", "account", "show", "--query", "user"]
}

resource "azurerm_virtual_network" "this" {
  name                = "${local.prefix}-vnet"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  address_space       = [var.cidr]
  tags                = local.tags
}

resource "azurerm_network_security_group" "this" {
  name                = "${local.prefix}-nsg"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  tags                = local.tags
}

resource "azurerm_subnet" "public" {
  name                 = "${local.prefix}-public"
  resource_group_name  = azurerm_resource_group.shared_rg.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.cidr, 3, 0)]

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_subnet" "private" {
  name                 = "${local.prefix}-private"
  resource_group_name  = azurerm_resource_group.shared_rg.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.cidr, 3, 1)]

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_subnet" "pe" {
  name                 = "${local.prefix}-pesubnet"
  resource_group_name  = azurerm_resource_group.shared_rg.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.cidr, 3, 2)]  # Get next subnet from the same CIDR
}
resource "azurerm_subnet_network_security_group_association" "pe" {
  subnet_id                 = azurerm_subnet.pe.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_databricks_workspace" "this" {
  name                        = "${local.prefix}-workspace"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  sku                         = "premium"
  managed_resource_group_name = "${local.prefix}-workspace-rg"
  tags                        = local.tags

  custom_parameters {
    no_public_ip                                         = var.no_public_ip
    virtual_network_id                                   = azurerm_virtual_network.this.id
    private_subnet_name                                  = azurerm_subnet.private.name
    public_subnet_name                                   = azurerm_subnet.public.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
  }
}

// Key Vault with defauilt access policy for the current user
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy

resource "azurerm_key_vault" "this" {
  name                     = "${local.prefix}-kv"
  location                 = azurerm_resource_group.shared_rg.location
  resource_group_name      = azurerm_resource_group.shared_rg.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  enabled_for_disk_encryption = true
}

resource "azurerm_key_vault_access_policy" "this" {
  key_vault_id       = azurerm_key_vault.this.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azurerm_client_config.current.object_id
  secret_permissions = ["Delete", "Get", "List", "Set","Recover"]
}

resource "azurerm_key_vault_secret" "databricks_secret_akv" {
    name         = "databricks-secret-${data.azurerm_client_config.current.tenant_id}"
    value        = "test secret from AKV"
    key_vault_id = azurerm_key_vault.this.id
    depends_on = [ azurerm_key_vault_access_policy.this ]
}

resource "azurerm_storage_account" "adls" {
  name                     = "${local.prefix}adls"
  resource_group_name      = azurerm_resource_group.shared_rg.name
  location                 = azurerm_resource_group.shared_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true  # ADLS Gen2
  min_tls_version          = "TLS1_2"
 # enable_https_traffic_only = true
  tags                     = local.tags
}
resource "azurerm_storage_container" "adls" {
  name                  = "demo"
 # storage_account_name  = azurerm_storage_account.adls.name
  storage_account_id    = azurerm_storage_account.adls.id
   container_access_type = "private"
}
resource "azurerm_storage_blob" "adls" {
  name                   = "demo.txt"
  storage_account_name   = azurerm_storage_account.adls.name
  storage_container_name = azurerm_storage_container.adls.name
  type                   = "Block"
  source                 = "${path.module}/demo.txt"
}
resource "azurerm_private_dns_zone" "dfs" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = azurerm_resource_group.shared_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dfs" {
  name                  = "${local.prefix}-vnetlink"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dfs.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

resource "azurerm_private_endpoint" "adls_pe" {
  name                = "${local.prefix}-adls-pe"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  subnet_id           = azurerm_subnet.pe.id

  private_service_connection {
    name                           = "${local.prefix}-adls-dfs-psc"
    private_connection_resource_id = azurerm_storage_account.adls.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  tags = local.tags
}
