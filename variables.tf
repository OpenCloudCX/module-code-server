# variable "eks_cluster_endpoint" {
#   type = string
# }

# variable "eks_cluster_auth_token" {
#   type = string
# }

# variable "eks_cluster_ca_certificate" {
#   type = string
# }

variable "namespace" {
  type = string
}

variable "dns_zone" {
  type    = string
  default = "opencloudcx.internal"
}

# variable "vpc_id" {
#   type = string
# }

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
  description = "Timeout value to wailt for helm chat deployment"
  type        = number
  default     = 600
}

