variable "namespace" {
  type = string
}

variable "dns_zone" {
  type    = string
  default = "opencloudcx.internal"
}

variable "helm_chart" {
  type    = string
  default = "https://helm.kodelib.com"
}

variable "helm_chart_name" {
  type    = string
  default = "code-server"
}

variable "helm_version" {
  type    = string
  default = "0.3.11"
}

variable "helm_timeout" {
  description = "Timeout value to wait for helm chart deployment"
  type        = number
  default     = 600
}

variable "stack" {
  type    = string
  default = ""
}