output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "workspace_name" {
  value = azurerm_machine_learning_workspace.this.name
}
