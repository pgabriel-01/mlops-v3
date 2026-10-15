variable "subscription_id" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "location_short" {
  type = string
}

variable "suffix" {
  type        = string
  description = "Deterministic 4 character suffix for globally unique names."
}

variable "network_mode" {
  type        = string
  default     = "public"
  description = "One of public, managed_internet, managed_approved or byo_vnet."

  validation {
    condition     = contains(["public", "managed_internet", "managed_approved", "byo_vnet"], var.network_mode)
    error_message = "network_mode must be public, managed_internet, managed_approved or byo_vnet."
  }
}

variable "feature_store" {
  type    = bool
  default = false
}

variable "registry" {
  type        = bool
  default     = false
  description = "Create the shared Azure ML registry (first environment only)."
}

variable "governance" {
  type    = bool
  default = false
}

variable "policy_mode" {
  type        = string
  default     = "audit"
  description = "Built-in Azure Policy guardrails: audit, deny or none."

  validation {
    condition     = contains(["audit", "deny", "none"], var.policy_mode)
    error_message = "policy_mode must be audit, deny or none."
  }
}

variable "genai" {
  type    = bool
  default = false
}

variable "existing_platform" {
  type        = bool
  default     = false
  description = "Reuse the supplied subnet, private DNS zones and Log Analytics workspace instead of creating them."
}

variable "vnet_address_space" {
  type    = string
  default = "10.20.0.0/16"
}

variable "allowed_fqdns" {
  type    = list(string)
  default = []
}

variable "compute_vm_size" {
  type    = string
  default = "Standard_DS3_v2"
}

variable "compute_max_nodes" {
  type    = number
  default = 4
}

variable "keyvault_retention_days" {
  type    = number
  default = 7
}

variable "budget_amount" {
  type    = number
  default = 0
}

variable "alert_emails" {
  type    = list(string)
  default = []
}

variable "existing_subnet_id" {
  type    = string
  default = ""
}

variable "existing_law_id" {
  type    = string
  default = ""
}

variable "existing_dns_zones" {
  type        = map(string)
  default     = {}
  description = "Optional keys: blob, file, vault, acr, aml_api, aml_notebooks (and cognitiveservices, openai, aiservices for genai)."
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "AVM module telemetry (anonymous deployment counters)."
}
