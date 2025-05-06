variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID to deploy the workspace into"
}

variable "region" {
  type    = string
  default = "centralus"
  description = "Azure region to deploy resources."
}
variable "cidr" {
  type        = string
  default     = "10.179.0.0/20"
  description = "Network range for created virtual network."
}

variable "no_public_ip" {
  type        = bool
  default     = true
  description = "Defines whether Secure Cluster Connectivity (No Public IP) should be enabled."
}


