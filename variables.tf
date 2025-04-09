variable "resource_group_name" {
  type    = string
  default = "zenml-resource-group"
}

variable "location" {
  type    = string
  default = "West Europe"
}

variable "container_app_name" {
  type    = string
  default = "zenml-container-app"
}

variable "environment_name" {
  type    = string
  default = "zenml-env"
}

variable "storage_account_name" {
  type    = string
  default = "zenmlstorageacc"
}

variable "key_vault_name" {
  type    = string
  default = "zenml-keyvault"
}

variable "mysql_server_name" {
  type    = string
  default = "zenml"
}

variable "mysql_admin_username" {
  type    = string
  default = "zenmladmin"
}

variable "mysql_admin_password" {
  type    = string
  default = "SecurePassword123!"
}

variable "domain_name" {
  type    = string
  default = "zenml.akouendy.com"
}

variable "jwt_secret_key" {
  type = string
}

variable "zenml_user_name" {
  type = string
}

variable "zenml_user_password" {
  type = string
}
variable "infra_resource_group_name" {
  type = string 
}

variable "infra_vnet_name" {
  type = string 
}
variable "infra_mysql_subnet_name" {
  type = string 
}

variable "infra_mysql_private_dns_zone_name" {
  description = "The name of the MySQL private DNS zone"
  type        = string
}

variable "location_short" {
  description = "Short name for the Azure region (used in resource names)"
  type        = string
  default     = ""
}

variable "resource_prefix" {
  description = "Prefix for all resources created by this module"
  type        = string
}