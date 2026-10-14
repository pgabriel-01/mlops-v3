# Governance: budget. Diagnostic settings and the workspace
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
