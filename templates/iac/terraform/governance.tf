# Governance: budget and policy assignment. Diagnostic settings and the workspace
# lock are set through the AVM module interfaces in main.tf (var.governance).

resource "azurerm_consumption_budget_resource_group" "this" {
  count             = var.governance && var.budget_amount > 0 ? 1 : 0
  name              = "budget-${var.project_name}-${var.environment}"
  resource_group_id = module.rg.resource_id
  amount            = var.budget_amount
  time_grain        = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-'01T00:00:00Z'", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.alert_emails
    contact_roles  = ["Owner"]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = var.alert_emails
    contact_roles  = ["Owner"]
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}

# Built-in 'Azure Machine Learning Workspaces should disable public network access' (audit)
# for private modes, otherwise built-in 'Require a tag on resources' reported only (not enforced).
resource "azurerm_resource_group_policy_assignment" "this" {
  count                = var.governance ? 1 : 0
  name                 = "mlops-${var.environment}-baseline"
  resource_group_id    = module.rg.resource_id
  policy_definition_id = local.private ? "/providers/Microsoft.Authorization/policyDefinitions/438c38d2-3772-465a-a9cc-7a6666a275ce" : "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
  enforce              = local.private
  parameters           = local.private ? null : jsonencode({ tagName = { value = "project" } })
}
