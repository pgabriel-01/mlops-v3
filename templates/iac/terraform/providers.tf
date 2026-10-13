terraform {
  required_version = ">= 1.16.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "[[versions.providers.azurerm]]"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "[[versions.providers.azapi]]"
    }
  }

  # Configured at init time (-backend-config) by the pipelines.
  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

provider "azapi" {
  subscription_id = var.subscription_id
}
