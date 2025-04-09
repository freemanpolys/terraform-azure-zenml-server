locals {
  use_existing_infra = alltrue([
    var.infra_resource_group_name != null,
    var.infra_vnet_name != null,
    var.infra_mysql_subnet_name != null,
  ])
}

locals {
   full_infra_vnet_id = try("/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.infra_resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.infra_vnet_name}", null)
   prefix_location = "${var.resource_prefix}-${var.location_short}"
}