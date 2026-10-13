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

variable "private_networking" {
  type    = bool
  default = false
}

variable "feature_store" {
  type    = bool
  default = false
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
