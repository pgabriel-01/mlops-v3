# Shared Azure ML registry; the generator enables it only in the first environment.
# No AVM module exists for Microsoft.MachineLearningServices/registries, so azapi is used.
resource "azapi_resource" "registry" {
  count     = var.registry ? 1 : 0
  type      = "Microsoft.MachineLearningServices/registries@2025-06-01"
  name      = "reg-${var.project_name}-${var.location_short}"
  location  = module.rg.location
  parent_id = module.rg.resource_id
  tags      = local.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      publicNetworkAccess = local.private ? "Disabled" : "Enabled"
      regionDetails = [{
        location = module.rg.location
        acrDetails = [{
          systemCreatedAcrAccount = { acrAccountSku = "Premium" }
        }]
        storageAccountDetails = [{
          systemCreatedStorageAccount = {
            storageAccountType    = "Standard_LRS"
            allowBlobPublicAccess = false
          }
        }]
      }]
    }
  }
}
