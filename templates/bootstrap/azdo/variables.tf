variable "subscription_id" { type = string }
variable "tenant_id" { type = string }
variable "project_name" { type = string }
variable "location" { type = string }
variable "location_short" { type = string }
variable "suffix" { type = string }
variable "environments" { type = list(string) }
variable "azdo_org_url" { type = string }
variable "azdo_project" { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_telemetry" {
  type    = bool
  default = true
}
