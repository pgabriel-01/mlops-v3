terraform {
  required_version = ">= 1.16.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "[[versions.providers.azurerm]]"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "[[versions.providers.azuredevops]]"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

provider "azuredevops" {
  org_service_url = var.azdo_org_url
}

locals {
  environments = toset(var.environments)
  base_name    = "${var.project_name}-bootstrap-${var.location_short}"
}

data "azuredevops_project" "this" {
  name = var.azdo_project
}

module "rg" {
  source           = "Azure/avm-res-resources-resourcegroup/azurerm"
  version          = "[[versions.avm_tf.res-resources-resourcegroup]]"
  name             = "rg-${local.base_name}"
  location         = var.location
  tags             = var.tags
  enable_telemetry = var.enable_telemetry
}

# State is accessed with Entra ID only: shared keys are disabled.
module "state_storage" {
  source                          = "Azure/avm-res-storage-storageaccount/azurerm"
  version                         = "[[versions.avm_tf.res-storage-storageaccount]]"
  name                            = "stt${var.project_name}${var.suffix}"
  location                        = module.rg.location
  parent_id                       = module.rg.resource_id
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  tags                            = var.tags
  enable_telemetry                = var.enable_telemetry

  blob_properties = {
    versioning_enabled = true
  }

  containers = {
    tfstate = {
      name = "tfstate"
    }
  }
}

module "deploy_identity" {
  for_each            = local.environments
  source              = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version             = "[[versions.avm_tf.res-managedidentity-userassignedidentity]]"
  name                = "id-${var.project_name}-${each.key}-${var.location_short}"
  location            = module.rg.location
  resource_group_name = module.rg.name
  tags                = var.tags
  enable_telemetry    = var.enable_telemetry
}

resource "azuredevops_serviceendpoint_azurerm" "env" {
  for_each                               = local.environments
  project_id                             = data.azuredevops_project.this.id
  service_endpoint_name                  = "${var.project_name}-${each.key}"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.subscription_id
  azurerm_subscription_name              = "${var.project_name}-${each.key}"

  credentials {
    serviceprincipalid = module.deploy_identity[each.key].client_id
  }
}

resource "azurerm_federated_identity_credential" "env" {
  for_each                  = local.environments
  name                      = "azdo-${each.key}"
  user_assigned_identity_id = module.deploy_identity[each.key].resource_id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azuredevops_serviceendpoint_azurerm.env[each.key].workload_identity_federation_issuer
  subject                   = azuredevops_serviceendpoint_azurerm.env[each.key].workload_identity_federation_subject
}

# Broad on purpose for the first deployment; scope down to the workload
# resource groups once they exist.
resource "azurerm_role_assignment" "contributor" {
  for_each             = local.environments
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = module.deploy_identity[each.key].principal_id
}

resource "azurerm_role_assignment" "access_admin" {
  for_each             = local.environments
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = module.deploy_identity[each.key].principal_id
}

resource "azurerm_role_assignment" "state" {
  for_each             = local.environments
  scope                = module.state_storage.resource_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.deploy_identity[each.key].principal_id
}

resource "azuredevops_git_repository" "this" {
  project_id = data.azuredevops_project.this.id
  name       = var.project_name
  initialization {
    init_type = "Clean"
  }
}

resource "azuredevops_environment" "env" {
  for_each   = local.environments
  project_id = data.azuredevops_project.this.id
  name       = each.key
}

resource "azuredevops_variable_group" "env" {
  for_each     = local.environments
  project_id   = data.azuredevops_project.this.id
  name         = "${var.project_name}-${each.key}"
  allow_access = true

  variable {
    name  = "TFSTATE_RESOURCE_GROUP"
    value = module.rg.name
  }
  variable {
    name  = "TFSTATE_STORAGE_ACCOUNT"
    value = module.state_storage.name
  }
  variable {
    name  = "TFSTATE_CONTAINER"
    value = "tfstate"
  }
}
