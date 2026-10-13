variable "subscription_id" { type = string }
variable "tenant_id" { type = string }
variable "project_name" { type = string }
variable "location" { type = string }
variable "location_short" { type = string }
variable "suffix" { type = string }
variable "environments" { type = list(string) }
variable "github_org" { type = string }
variable "github_repo" { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}
