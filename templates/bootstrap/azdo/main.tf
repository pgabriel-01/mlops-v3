terraform {
  required_version = ">= 1.16.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> [[versions.providers.azurerm]]"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> [[versions.providers.azuredevops]]"
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

resource "azurerm_resource_group" "state" {
  name     = "rg-${local.base_name}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "state" {
  name                            = "stt${var.project_name}${var.suffix}"
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  tags                            = var.tags

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_user_assigned_identity" "deploy" {
  for_each            = local.environments
  name                = "id-${var.project_name}-${each.key}-${var.location_short}"
  resource_group_name = azurerm_resource_group.state.name
  location            = azurerm_resource_group.state.location
  tags                = var.tags
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
    serviceprincipalid = azurerm_user_assigned_identity.deploy[each.key].client_id
  }
}

resource "azurerm_federated_identity_credential" "env" {
  for_each                  = local.environments
  name                      = "azdo-${each.key}"
  user_assigned_identity_id = azurerm_user_assigned_identity.deploy[each.key].id
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
  principal_id         = azurerm_user_assigned_identity.deploy[each.key].principal_id
}

resource "azurerm_role_assignment" "access_admin" {
  for_each             = local.environments
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azurerm_user_assigned_identity.deploy[each.key].principal_id
}

resource "azurerm_role_assignment" "state" {
  for_each             = local.environments
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.deploy[each.key].principal_id
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
    value = azurerm_resource_group.state.name
  }
  variable {
    name  = "TFSTATE_STORAGE_ACCOUNT"
    value = azurerm_storage_account.state.name
  }
  variable {
    name  = "TFSTATE_CONTAINER"
    value = azurerm_storage_container.state.name
  }
}
