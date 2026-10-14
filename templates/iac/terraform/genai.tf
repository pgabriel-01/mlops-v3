# AI Foundry: AI Services account, Hub workspace and a Project workspace.

module "ai_services" {
  count                         = var.genai ? 1 : 0
  source                        = "Azure/avm-res-cognitiveservices-account/azurerm"
  version                       = "[[versions.avm_tf.res-cognitiveservices-account]]"
  name                          = "ais-${var.project_name}-${var.environment}-${var.location_short}"
  location                      = module.rg.location
  parent_id                     = module.rg.resource_id
  kind                          = "AIServices"
  sku_name                      = "S0"
  custom_subdomain_name         = "ais-${var.project_name}-${var.environment}-${var.suffix}"
  public_network_access_enabled = !local.private
  local_auth_enabled            = false
  managed_identities            = { system_assigned = true }
  tags                          = local.tags
  enable_telemetry              = var.enable_telemetry

  private_endpoints = local.byo_vnet ? {
    account = {
      subnet_resource_id = local.pe_subnet_id
      private_dns_zone_resource_ids = setunion(
        local.zone_sets.cognitiveservices,
        local.zone_sets.openai,
        local.zone_sets.aiservices
      )
    }
  } : {}

  role_assignments = {
    hub = {
      role_definition_id_or_name = "Cognitive Services User"
      principal_id               = module.hub[0].system_assigned_mi_principal_id
      principal_type             = "ServicePrincipal"
    }
  }

  diagnostic_settings = local.diag_settings
}

module "hub" {
  count                         = var.genai ? 1 : 0
  source                        = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version                       = "[[versions.avm_tf.res-machinelearningservices-workspace]]"
  name                          = "hub-${var.project_name}-${var.environment}-${var.location_short}"
  location                      = module.rg.location
  resource_group_name           = element(split("/", module.rg.resource_id), 4)
  kind                          = "Hub"
  storage_account               = { resource_id = module.storage.resource_id }
  key_vault                     = { resource_id = module.key_vault.resource_id }
  container_registry            = { resource_id = module.acr.resource_id }
  application_insights          = { resource_id = module.app_insights.resource_id }
  managed_identities            = { system_assigned = true }
  public_network_access_enabled = !local.private
  tags                          = local.tags
  enable_telemetry              = var.enable_telemetry

  private_endpoints = local.byo_vnet ? {
    amlworkspace = {
      subnet_resource_id            = local.pe_subnet_id
      private_dns_zone_resource_ids = setunion(local.zone_sets.aml_api, local.zone_sets.aml_notebooks)
    }
  } : {}
}

resource "azapi_resource" "hub_ai_services_connection" {
  count     = var.genai ? 1 : 0
  type      = "Microsoft.MachineLearningServices/workspaces/connections@2025-06-01"
  name      = "aiservices"
  parent_id = module.hub[0].resource_id

  body = {
    properties = {
      category      = "AIServices"
      target        = module.ai_services[0].endpoint
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = module.ai_services[0].resource_id
      }
    }
  }
}

module "project" {
  count                         = var.genai ? 1 : 0
  source                        = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version                       = "[[versions.avm_tf.res-machinelearningservices-workspace]]"
  name                          = "proj-${var.project_name}-${var.environment}-${var.location_short}"
  location                      = module.rg.location
  resource_group_name           = element(split("/", module.rg.resource_id), 4)
  kind                          = "Project"
  azure_ai_hub                  = { resource_id = module.hub[0].resource_id }
  managed_identities            = { system_assigned = true }
  public_network_access_enabled = !local.private
  tags                          = local.tags
  enable_telemetry              = var.enable_telemetry

  depends_on = [azapi_resource.hub_ai_services_connection]
}
