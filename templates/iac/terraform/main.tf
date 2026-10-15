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

  managed_vnet = contains(["managed_internet", "managed_approved"], var.network_mode)
  byo_vnet     = var.network_mode == "byo_vnet"
  private      = var.network_mode != "public"

  create_vnet = local.byo_vnet && !var.existing_platform
  create_law  = !(var.existing_platform && var.existing_law_id != "")
  law_id      = local.create_law ? module.log_analytics[0].resource_id : var.existing_law_id

  pe_subnet_id      = local.byo_vnet ? (var.existing_platform ? var.existing_subnet_id : module.vnet[0].subnets["pe"].resource_id) : null
  compute_subnet_id = local.byo_vnet ? (var.existing_platform ? var.existing_subnet_id : module.vnet[0].subnets["compute"].resource_id) : null

  isolation_mode = {
    managed_internet = "AllowInternetOutbound"
    managed_approved = "AllowOnlyApprovedOutbound"
  }
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
  count                                     = local.create_law ? 1 : 0
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
  workspace_id        = local.law_id
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
  public_network_access_enabled = !local.private
  network_rules                 = local.private ? {} : null
  tags                          = local.tags
  enable_telemetry              = var.enable_telemetry

  private_endpoints = local.byo_vnet ? {
    blob = {
      name                          = "pe-${local.storage_name}-blob"
      subnet_resource_id            = local.pe_subnet_id
      subresource_name              = "blob"
      private_dns_zone_resource_ids = local.zone_sets.blob
    }
    file = {
      name                          = "pe-${local.storage_name}-file"
      subnet_resource_id            = local.pe_subnet_id
      subresource_name              = "file"
      private_dns_zone_resource_ids = local.zone_sets.file
    }
  } : {}

  diagnostic_settings_storage_account = local.diag_settings
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
  soft_delete_retention_days    = var.keyvault_retention_days
  public_network_access_enabled = !local.private
  tags                          = local.tags
  enable_telemetry              = var.enable_telemetry

  private_endpoints = local.byo_vnet ? {
    vault = {
      subnet_resource_id            = local.pe_subnet_id
      subresource_name              = "vault"
      private_dns_zone_resource_ids = local.zone_sets.vault
    }
  } : {}

  diagnostic_settings = local.diag_settings
}

module "acr" {
  source                        = "Azure/avm-res-containerregistry-registry/azurerm"
  version                       = "[[versions.avm_tf.res-containerregistry-registry]]"
  name                          = local.acr_name
  location                      = module.rg.location
  resource_group_name           = module.rg.name
  sku                           = local.private ? "Premium" : "Standard"
  admin_enabled                 = false
  zone_redundancy_enabled       = local.private
  public_network_access_enabled = !local.private
  tags                          = local.tags
  enable_telemetry              = var.enable_telemetry

  private_endpoints = local.byo_vnet ? {
    registry = {
      subnet_resource_id            = local.pe_subnet_id
      private_dns_zone_resource_ids = local.zone_sets.acr
    }
  } : {}

  diagnostic_settings = local.diag_settings
}

module "workspace" {
  source                        = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version                       = "[[versions.avm_tf.res-machinelearningservices-workspace]]"
  name                          = module.naming.machine_learning_workspace.name
  location                      = module.rg.location
  resource_group_name           = element(split("/", module.rg.resource_id), 4)
  storage_account               = { resource_id = module.storage.resource_id }
  key_vault                     = { resource_id = module.key_vault.resource_id }
  container_registry            = { resource_id = module.acr.resource_id }
  application_insights          = { resource_id = module.app_insights.resource_id }
  managed_identities            = { system_assigned = true }
  public_network_access_enabled = !local.private
  provision_network_now_enabled = local.managed_vnet
  tags                          = local.tags
  enable_telemetry              = var.enable_telemetry

  # Private endpoints and DNS zone groups live inside these modules; wait for all of them.
  depends_on = [module.storage, module.key_vault, module.acr, module.app_insights]

  workspace_managed_network = {
    isolation_mode = local.managed_vnet ? local.isolation_mode[var.network_mode] : "Disabled"
    outbound_rules = {
      fqdn = local.managed_vnet && var.network_mode == "managed_approved" ? {
        for i, f in var.allowed_fqdns : "fqdn-${i}" => { destination = f }
      } : {}
    }
  }

  private_endpoints = local.byo_vnet ? {
    amlworkspace = {
      subnet_resource_id            = local.pe_subnet_id
      private_dns_zone_resource_ids = local.zone_sets_aml
    }
  } : {}

  lock                = var.governance ? { kind = "CanNotDelete", name = "lock-workspace" } : null
  diagnostic_settings = local.diag_settings
}

resource "azurerm_machine_learning_compute_cluster" "cpu" {
  name                          = "cpu-cluster"
  location                      = module.rg.location
  machine_learning_workspace_id = module.workspace.resource_id
  vm_priority                   = "Dedicated"
  vm_size                       = var.compute_vm_size
  node_public_ip_enabled        = !local.private
  local_auth_enabled            = false
  subnet_resource_id            = local.compute_subnet_id

  # A cluster without public IPs needs the workspace private endpoint, which lives inside the module.
  depends_on = [module.workspace]

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = var.compute_max_nodes
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

  depends_on = [module.storage, module.key_vault, module.app_insights]

  body = {
    kind = "FeatureStore"
    sku = {
      name = "Basic"
      tier = "Basic"
    }
    properties = {
      description         = "Managed feature store for ${var.project_name} (${var.environment})"
      storageAccount      = module.storage.resource_id
      keyVault            = module.key_vault.resource_id
      applicationInsights = module.app_insights.resource_id
      publicNetworkAccess = local.private ? "Disabled" : "Enabled"
      # Serverless Spark needs a managed network, and allow_internet_outbound is the only mode feature stores support.
      managedNetwork = {
        isolationMode = "AllowInternetOutbound"
      }
      featureStoreSettings = {
        computeRuntime = { sparkRuntimeVersion = "3.4.0" }
      }
    }
  }
}
