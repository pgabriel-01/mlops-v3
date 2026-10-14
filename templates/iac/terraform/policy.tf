# Built-in Azure Policy guardrails on the environment resource group.
# policy_mode: audit reports only, deny blocks non-compliant changes, none skips assignment.

locals {
  policy_effect = var.policy_mode == "deny" ? "Deny" : "Audit"

  policies = var.policy_mode == "none" ? {} : merge(
    {
      # Azure Machine Learning Computes should have local authentication methods disabled
      compute-local-auth = {
        id      = "e96a9a5f-07ca-471b-9bc5-6a0f33cbd68f"
        params  = { effect = { value = local.policy_effect } }
        enforce = true
      }
      # Require a tag on resources (the effect is fixed to deny, so audit mode does not enforce it)
      require-project-tag = {
        id      = "871b6d14-10aa-478d-b590-94f262ecfa99"
        params  = { tagName = { value = "project" } }
        enforce = var.policy_mode == "deny"
      }
    },
    local.private ? {
      # Azure Machine Learning Workspaces should disable public network access
      workspace-no-public-access = {
        id      = "438c38d2-3772-465a-a9cc-7a6666a275ce"
        params  = { effect = { value = local.policy_effect } }
        enforce = true
      }
    } : {}
  )
}

resource "azurerm_resource_group_policy_assignment" "guardrail" {
  for_each             = local.policies
  name                 = substr("mlops-${var.environment}-${each.key}", 0, 64)
  resource_group_id    = module.rg.resource_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/${each.value.id}"
  enforce              = each.value.enforce
  parameters           = jsonencode(each.value.params)
}
