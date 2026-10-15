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
  private      = var.use_private_networking
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

# State is accessed with Entra ID only: shared keys are disabled. The endpoint is public unless
# use_private_networking is set; then it is reachable only through a private endpoint from the self-hosted runners' VNet.
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
  public_network_access_enabled   = !local.private
  tags                            = var.tags
  enable_telemetry                = var.enable_telemetry

  network_rules = {
    default_action = local.private ? "Deny" : "Allow"
    bypass         = local.private ? ["None"] : ["AzureServices"]
  }

  private_endpoints = local.private ? {
    blob = {
      subnet_resource_id            = module.runners[0].private_dns_zone_subnet_resource_id
      subresource_name              = "blob"
      private_dns_zone_resource_ids = [module.blob_dns[0].resource_id]
    }
  } : {}

  blob_properties = {
    versioning_enabled = true
  }

  containers = {
    tfstate = {
      name = "tfstate"
    }
  }
}

# Optional private networking: ACI-based self-hosted GitHub runners in a VNet (NAT gateway for egress),
# plus a private endpoint and DNS for the state storage. Same approach as the ALZ Accelerator.
module "runners" {
  count   = local.private ? 1 : 0
  source  = "Azure/avm-ptn-cicd-agents-and-runners/azurerm"
  version = "[[versions.avm_tf.ptn-cicd-agents-and-runners]]"

  location                                     = module.rg.location
  postfix                                      = "${var.project_name}-${var.suffix}"
  parent_id                                    = module.rg.resource_id
  resource_group_creation_enabled              = false
  compute_types                                = ["azure_container_instance"]
  version_control_system_type                  = "github"
  version_control_system_organization          = var.github_org
  version_control_system_repository            = github_repository.this.name
  version_control_system_authentication_method = "pat"
  version_control_system_personal_access_token = var.github_runners_token
  use_private_networking                       = true
  virtual_network_address_space                = var.runners_vnet_address_space
  tags                                         = var.tags
  enable_telemetry                             = var.enable_telemetry
}

module "blob_dns" {
  count            = local.private ? 1 : 0
  source           = "Azure/avm-res-network-privatednszone/azurerm"
  version          = "[[versions.avm_tf.res-network-privatednszone]]"
  domain_name      = "privatelink.blob.core.windows.net"
  parent_id        = module.rg.resource_id
  tags             = var.tags
  enable_telemetry = var.enable_telemetry

  virtual_network_links = {
    runners = {
      name               = "link-runners"
      virtual_network_id = module.runners[0].virtual_network_resource_id
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
}

# Declared here rather than through the identity module, whose latest release still uses the
# deprecated parent_id argument and prints a warning on every plan.
resource "azurerm_federated_identity_credential" "env" {
  for_each                  = local.environments
  name                      = "gh-${each.key}"
  user_assigned_identity_id = module.deploy_identity.resource_id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${var.github_org}@${data.github_user.owner.id}/${github_repository.this.name}@${github_repository.this.repo_id}:environment:${each.key}"
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

# GitHub issues ID-based OIDC subjects for new repositories (repo:owner@ownerId/repo@repoId:...).
data "github_user" "owner" {
  username = var.github_org
}

data "github_user" "approver" {
  for_each = toset(var.approvers)
  username = each.key
}

resource "github_repository_environment" "env" {
  for_each    = local.environments
  repository  = github_repository.this.name
  environment = each.key

  dynamic "reviewers" {
    for_each = each.key != "dev" && length(var.approvers) > 0 ? [1] : []
    content {
      users = [for u in data.github_user.approver : u.id]
    }
  }

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
