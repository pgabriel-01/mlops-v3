output "resource_group_name" {
  value = module.rg.name
}

output "workspace_name" {
  value = module.naming.machine_learning_workspace.name
}
