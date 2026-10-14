terraform {
  required_version = ">= 1.16.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "[[versions.providers.azurerm]]"
    }
    github = {
      source  = "integrations/github"
      version = "[[versions.providers.github]]"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

provider "github" {
  owner = var.github_org
}

locals {
  environments = toset(var.environments)
  base_name    = "${var.project_name}-bootstrap-${var.location_short}"
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
  source              = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version             = "[[versions.avm_tf.res-managedidentity-userassignedidentity]]"
  name                = "id-${local.base_name}"
  location            = module.rg.location
  resource_group_name = module.rg.name
  tags                = var.tags
  enable_telemetry    = var.enable_telemetry

  federated_identity_credentials = {
    for env in local.environments : env => {
      name     = "gh-${env}"
      audience = ["api://AzureADTokenExchange"]
      issuer   = "https://token.actions.githubusercontent.com"
      subject  = "repo:${var.github_org}/${var.github_repo}:environment:${env}"
    }
  }
}

# Broad on purpose for the first deployment; scope down to the workload
# resource groups once they exist.
resource "azurerm_role_assignment" "contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = module.deploy_identity.principal_id
}

resource "azurerm_role_assignment" "access_admin" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = module.deploy_identity.principal_id
}

# Needed to assign the built-in policy guardrails (policy_mode); Contributor cannot write policy assignments.
resource "azurerm_role_assignment" "policy" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Resource Policy Contributor"
  principal_id         = module.deploy_identity.principal_id
}

resource "azurerm_role_assignment" "state" {
  scope                = module.state_storage.resource_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.deploy_identity.principal_id
}

resource "github_repository" "this" {
  name                   = var.github_repo
  description            = "MLOps v3 workload for ${var.project_name}"
  visibility             = "private"
  auto_init              = true
  delete_branch_on_merge = true
  has_issues             = true
}

resource "github_repository_environment" "env" {
  for_each    = local.environments
  repository  = github_repository.this.name
  environment = each.key

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "main" {
  for_each       = local.environments
  repository     = github_repository.this.name
  environment    = github_repository_environment.env[each.key].environment
  branch_pattern = "main"
}

locals {
  env_variables = {
    AZURE_CLIENT_ID         = module.deploy_identity.client_id
    AZURE_TENANT_ID         = var.tenant_id
    AZURE_SUBSCRIPTION_ID   = var.subscription_id
    TFSTATE_RESOURCE_GROUP  = module.rg.name
    TFSTATE_STORAGE_ACCOUNT = module.state_storage.name
    TFSTATE_CONTAINER       = "tfstate"
  }
  env_variable_pairs = {
    for pair in setproduct(var.environments, keys(local.env_variables)) :
    "${pair[0]}/${pair[1]}" => { env = pair[0], name = pair[1], value = local.env_variables[pair[1]] }
  }
}

resource "github_actions_environment_variable" "this" {
  for_each      = local.env_variable_pairs
  repository    = github_repository.this.name
  environment   = github_repository_environment.env[each.value.env].environment
  variable_name = each.value.name
  value         = each.value.value
}
