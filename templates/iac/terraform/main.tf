data "azurerm_client_config" "current" {}

locals {
  base_name = "${var.project_name}-${var.environment}-${var.location_short}"
  tags = merge(var.tags, {
    project     = var.project_name
    environment = var.environment
    managed-by  = "mlops-v3"
  })
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.base_name}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${local.base_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${local.base_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = local.tags
}

resource "azurerm_storage_account" "this" {
  name                            = "st${var.project_name}${var.environment}${var.suffix}"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  account_tier                    = "Standard"
  account_replication_type        = var.environment == "prod" ? "ZRS" : "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = !var.private_networking
  tags                            = local.tags
}

resource "azurerm_key_vault" "this" {
  name                          = "kv-${var.project_name}-${var.environment}-${var.suffix}"
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  public_network_access_enabled = !var.private_networking
  tags                          = local.tags
}

resource "azurerm_container_registry" "this" {
  name                          = "cr${var.project_name}${var.environment}${var.suffix}"
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  sku                           = var.private_networking ? "Premium" : "Standard"
  admin_enabled                 = false
  public_network_access_enabled = !var.private_networking
  tags                          = local.tags
}

resource "azurerm_machine_learning_workspace" "this" {
  name                          = "mlw-${local.base_name}"
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  application_insights_id       = azurerm_application_insights.this.id
  key_vault_id                  = azurerm_key_vault.this.id
  storage_account_id            = azurerm_storage_account.this.id
  container_registry_id         = azurerm_container_registry.this.id
  public_network_access_enabled = !var.private_networking
  tags                          = local.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_machine_learning_compute_cluster" "cpu" {
  name                          = "cpu-cluster"
  location                      = azurerm_resource_group.this.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.this.id
  vm_priority                   = "Dedicated"
  vm_size                       = "Standard_DS3_v2"

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 4
    scale_down_nodes_after_idle_duration = "PT15M"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azapi_resource" "feature_store" {
  count     = var.feature_store ? 1 : 0
  type      = "Microsoft.MachineLearningServices/workspaces@2025-06-01"
  name      = "fs-${local.base_name}"
  location  = azurerm_resource_group.this.location
  parent_id = azurerm_resource_group.this.id
  tags      = local.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "FeatureStore"
    sku = {
      name = "Basic"
      tier = "Basic"
    }
    properties = {
      description         = "Managed feature store for ${var.project_name} (${var.environment})"
      publicNetworkAccess = var.private_networking ? "Disabled" : "Enabled"
    }
  }
}
