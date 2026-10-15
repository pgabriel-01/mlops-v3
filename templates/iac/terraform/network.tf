# Bring-your-own VNet: spoke VNet, subnets and private DNS zones.
# With existing_platform = true nothing here is created; the supplied subnet and zones are used.

locals {
  dns_domains = merge(
    {
      blob          = "privatelink.blob.core.windows.net"
      file          = "privatelink.file.core.windows.net"
      vault         = "privatelink.vaultcore.azure.net"
      acr           = "privatelink.azurecr.io"
      aml_api       = "privatelink.api.azureml.ms"
      aml_notebooks = "privatelink.notebooks.azure.net"
    },
    var.genai ? {
      cognitiveservices = "privatelink.cognitiveservices.azure.com"
      openai            = "privatelink.openai.azure.com"
      aiservices        = "privatelink.services.ai.azure.com"
    } : {},
    var.rag ? { search = "privatelink.search.windows.net" } : {}
  )

  # Whether a zone exists is decided from known values only, so the private endpoint modules can
  # evaluate length(private_dns_zone_resource_ids) at plan time while the zone IDs are still unknown.
  zone_lists = {
    for k in keys(local.dns_domains) : k => (
      var.existing_platform
      ? (lookup(var.existing_dns_zones, k, "") == "" ? [] : [var.existing_dns_zones[k]])
      : (local.create_vnet ? [module.dns[k].resource_id] : [])
    )
  }
  zone_sets     = { for k, v in local.zone_lists : k => toset(v) }
  zone_sets_aml = toset(concat(local.zone_lists.aml_api, local.zone_lists.aml_notebooks))
  zone_sets_genai = toset(var.genai ? concat(
    local.zone_lists.cognitiveservices, local.zone_lists.openai, local.zone_lists.aiservices
  ) : [])

  # Shared by every resource that supports diagnostic settings.
  diag_settings = var.governance ? {
    to_law = {
      name                  = "diag-to-law"
      workspace_resource_id = local.law_id
    }
  } : {}

  # The storage module has no default categories, and an account-level setting has no log categories.
  storage_diag_settings = var.governance ? {
    to_law = {
      name                  = "diag-to-law"
      workspace_resource_id = local.law_id
      metrics               = [{ category = "Transaction" }]
    }
  } : {}
}

module "vnet" {
  count            = local.create_vnet ? 1 : 0
  source           = "Azure/avm-res-network-virtualnetwork/azurerm"
  version          = "[[versions.avm_tf.res-network-virtualnetwork]]"
  name             = module.naming.virtual_network.name
  location         = module.rg.location
  parent_id        = module.rg.resource_id
  address_space    = [var.vnet_address_space]
  tags             = local.tags
  enable_telemetry = var.enable_telemetry

  subnets = {
    pe = {
      name             = "snet-pe"
      address_prefixes = [cidrsubnet(var.vnet_address_space, 8, 0)]
    }
    compute = {
      name             = "snet-compute"
      address_prefixes = [cidrsubnet(var.vnet_address_space, 4, 1)]
    }
  }
}

module "dns" {
  for_each         = local.create_vnet ? local.dns_domains : {}
  source           = "Azure/avm-res-network-privatednszone/azurerm"
  version          = "[[versions.avm_tf.res-network-privatednszone]]"
  domain_name      = each.value
  parent_id        = module.rg.resource_id
  tags             = local.tags
  enable_telemetry = var.enable_telemetry

  virtual_network_links = {
    spoke = {
      name               = "link-${module.naming.virtual_network.name}"
      virtual_network_id = module.vnet[0].resource_id
    }
  }
}
