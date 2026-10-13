output "resource_group_name" {
  value = module.rg.name
}

output "workspace_name" {
  value = module.naming.machine_learning_workspace.name
}

output "registry_name" {
  value = var.registry ? azapi_resource.registry[0].name : null
}

output "hub_name" {
  value = var.genai ? module.hub[0].workspace.name : null
}

output "project_name" {
  value = var.genai ? module.project[0].workspace.name : null
}

output "vnet_id" {
  value = local.create_vnet ? module.vnet[0].resource_id : null
}
