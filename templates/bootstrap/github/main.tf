terraform {
  required_version = ">= 1.16.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> [[versions.providers.azurerm]]"
    }
    github = {
      source  = "integrations/github"
      version = "~> [[versions.providers.github]]"
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
  name                = "id-${local.base_name}"
  resource_group_name = azurerm_resource_group.state.name
  location            = azurerm_resource_group.state.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "env" {
  for_each                  = local.environments
  name                      = "gh-${each.key}"
  user_assigned_identity_id = azurerm_user_assigned_identity.deploy.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${var.github_org}/${var.github_repo}:environment:${each.key}"
}

# Broad on purpose for the first deployment; scope down to the workload
# resource groups once they exist.
resource "azurerm_role_assignment" "contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.deploy.principal_id
}

resource "azurerm_role_assignment" "access_admin" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azurerm_user_assigned_identity.deploy.principal_id
}

resource "azurerm_role_assignment" "state" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.deploy.principal_id
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
    AZURE_CLIENT_ID         = azurerm_user_assigned_identity.deploy.client_id
    AZURE_TENANT_ID         = var.tenant_id
    AZURE_SUBSCRIPTION_ID   = var.subscription_id
    TFSTATE_RESOURCE_GROUP  = azurerm_resource_group.state.name
    TFSTATE_STORAGE_ACCOUNT = azurerm_storage_account.state.name
    TFSTATE_CONTAINER       = azurerm_storage_container.state.name
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
