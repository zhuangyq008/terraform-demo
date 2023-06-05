variable "region" {
  default = "eu-central-1"
}

variable "cluster_name" {
  default = "devax-demo"
}
variable "vpc_id" {
  type = string
}
variable "private_subnets" {
  type = list(string)
}
variable "grafana_endpoint" {
  description = "Grafana endpoint"
  type        = string
  default     = null
}

variable "grafana_api_key" {
  description = "API key for authorizing the Grafana provider to make changes to Amazon Managed Grafana"
  type        = string
  default     = ""
  sensitive   = true
}

variable "secret_role_name" {
  default = "devax-eshop-external-secrets-role"
}