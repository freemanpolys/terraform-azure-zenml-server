# Data Sources
# Get the current user details
data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "infra_vnet_rg" {
    count = local.use_existing_infra ? 1 : 0
    name = var.infra_resource_group_name
}
data "azurerm_virtual_network" "infra_vnet" {
    count = local.use_existing_infra ? 1 : 0
    name                = var.infra_vnet_name
    resource_group_name = data.azurerm_resource_group.infra_vnet_rg[0].name
}
data "azurerm_subnet" "mysql_subnet" {
    count = local.use_existing_infra ? 1 : 0
    name                 = var.infra_mysql_subnet_name
    resource_group_name  = data.azurerm_resource_group.infra_vnet_rg[0].name
    virtual_network_name = data.azurerm_virtual_network.infra_vnet[0].name
}

data "azurerm_private_dns_zone" "infra_mysql_zone" {
    count = local.use_existing_infra ? 1 : 0
    name                = var.infra_mysql_private_dns_zone_name
    resource_group_name = data.azurerm_resource_group.infra_vnet_rg[0].name
}