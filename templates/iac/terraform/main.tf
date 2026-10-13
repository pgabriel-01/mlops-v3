data "azurerm_client_config" "current" {}

# Utility module: validates the region against the published Azure region list.
module "regions" {
  source           = "Azure/avm-utl-regions/azurerm"
  version          = "[[versions.avm_tf.utl-regions]]"
  enable_telemetry = var.enable_telemetry
}

check "valid_region" {
  assert {
    condition     = contains(module.regions.valid_region_names, var.location)
    error_message = "location '${var.location}' is not a valid Azure region name."
  }
}

# Utility module: CAF-aligned resource names.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "[[versions.tf_modules.naming]]"
  suffix  = [var.project_name, var.environment, var.location_short]
}

locals {
  tags = merge(var.tags, {
    project     = var.project_name
    environment = var.environment
    managed-by  = "mlops-v3"
  })
  # Storage, Key Vault and ACR names are global; add the deterministic suffix.
  storage_name  = substr("st${var.project_name}${var.environment}${var.suffix}", 0, 24)
  keyvault_name = substr("kv-${var.project_name}-${var.environment}-${var.suffix}", 0, 24)
  acr_name      = "cr${var.project_name}${var.environment}${var.suffix}"
}

module "rg" {
  source           = "Azure/avm-res-resources-resourcegroup/azurerm"
  version          = "[[versions.avm_tf.res-resources-resourcegroup]]"
  name             = module.naming.resource_group.name
  location         = var.location
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}

module "log_analytics" {
  source                                    = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version                                   = "[[versions.avm_tf.res-operationalinsights-workspace]]"
  name                                      = module.naming.log_analytics_workspace.name
  location                                  = module.rg.location
  resource_group_name                       = module.rg.name
  log_analytics_workspace_sku               = "PerGB2018"
  log_analytics_workspace_retention_in_days = 30
  tags                                      = local.tags
  enable_telemetry                          = var.enable_telemetry
}

module "app_insights" {
  source              = "Azure/avm-res-insights-component/azurerm"
  version             = "[[versions.avm_tf.res-insights-component]]"
  name                = module.naming.application_insights.name
  location            = module.rg.location
  resource_group_name = module.rg.name
  workspace_id        = module.log_analytics.resource_id
  application_type    = "web"
  tags                = local.tags
  enable_telemetry    = var.enable_telemetry
}

module "storage" {
  source                          = "Azure/avm-res-storage-storageaccount/azurerm"
  version                         = "[[versions.avm_tf.res-storage-storageaccount]]"
  name                            = local.storage_name
  location                        = module.rg.location
  parent_id                       = module.rg.resource_id
  account_tier                    = "Standard"
  account_replication_type        = var.environment == "prod" ? "ZRS" : "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  # Azure ML's default datastore uses account keys unless identity-based access is configured.
  shared_access_key_enabled     = true
  public_network_access_enabled = !var.private_networking
  tags                          = local.tags
  enable_telemetry              = var.enable_telemetry
}

module "key_vault" {
  source                        = "Azure/avm-res-keyvault-vault/azurerm"
  version                       = "[[versions.avm_tf.res-keyvault-vault]]"
  name                          = local.keyvault_name
  location                      = module.rg.location
  resource_group_name           = module.rg.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  public_network_access_enabled = !var.private_networking
  tags                          = local.tags
  enable_telemetry              = var.enable_telemetry
}

module "acr" {
  source                        = "Azure/avm-res-containerregistry-registry/azurerm"
  version                       = "[[versions.avm_tf.res-containerregistry-registry]]"
  name                          = local.acr_name
  location                      = module.rg.location
  resource_group_name           = module.rg.name
  sku                           = var.private_networking ? "Premium" : "Standard"
  admin_enabled                 = false
  public_network_access_enabled = !var.private_networking
  tags                          = local.tags
  enable_telemetry              = var.enable_telemetry
}

module "workspace" {
  source                        = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version                       = "[[versions.avm_tf.res-machinelearningservices-workspace]]"
  name                          = module.naming.machine_learning_workspace.name
  location                      = module.rg.location
  resource_group_name           = module.rg.name
  storage_account               = { resource_id = module.storage.resource_id }
  key_vault                     = { resource_id = module.key_vault.resource_id }
  container_registry            = { resource_id = module.acr.resource_id }
  application_insights          = { resource_id = module.app_insights.resource_id }
  managed_identities            = { system_assigned = true }
  public_network_access_enabled = !var.private_networking
  tags                          = local.tags
  enable_telemetry              = var.enable_telemetry
}

resource "azurerm_machine_learning_compute_cluster" "cpu" {
  name                          = "cpu-cluster"
  location                      = module.rg.location
  machine_learning_workspace_id = module.workspace.resource_id
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
  name      = "fs-${var.project_name}-${var.environment}-${var.location_short}"
  location  = module.rg.location
  parent_id = module.rg.resource_id
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
