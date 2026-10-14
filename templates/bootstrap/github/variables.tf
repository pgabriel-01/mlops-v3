variable "subscription_id" { type = string }
variable "tenant_id" { type = string }
variable "project_name" { type = string }
variable "location" { type = string }
variable "location_short" { type = string }
variable "suffix" { type = string }
variable "environments" { type = list(string) }
variable "github_org" { type = string }
variable "approvers" {
  type    = list(string)
  default = []
}
variable "github_repo" { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_telemetry" {
  type    = bool
  default = true
}

variable "use_private_networking" {
  type    = bool
  default = false
}

variable "runners_vnet_address_space" {
  type    = string
  default = "10.250.0.0/24"
}

variable "github_runners_token" {
  type      = string
  default   = ""
  sensitive = true
}
