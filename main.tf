# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.prefix_location}-${var.resource_group_name}"
  location = var.location
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${local.prefix_location}-${var.resource_group_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Container Apps Environment
resource "azurerm_container_app_environment" "env" {
  name                       = "appenv-${local.prefix_location}-${var.environment_name}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  infrastructure_subnet_id   = azurerm_subnet.container_subnet.id
}


# Azure Key Vault
resource "azurerm_key_vault" "kv" {
  name                      = "kv-${var.location_short}-${var.key_vault_name}"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name
  sku_name                  = "standard"
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization = true

}

# Assign Key Vault Contributor role to the current user
resource "azurerm_role_assignment" "rbac" {
  scope                = azurerm_key_vault.kv.id
  for_each             = toset(["Key Vault Administrator", "Key Vault Secrets Officer"])
  role_definition_name = each.key
  principal_id         = data.azurerm_client_config.current.object_id
}


# Azure Blob Storage for log analytics
resource "azurerm_storage_account" "storage" {
  name                     = "sa${var.location_short}${var.storage_account_name}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "blob_container" {
  name                  = "sc-${local.prefix_location}-zenml-artifacts"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}
# adding a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.prefix_location}-zenml-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

# adding a subnet
resource "azurerm_subnet" "mysql_subnet" {
  name                 = "subnet-${local.prefix_location}-zenml-mysql-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
delegation {
  name = "mysql-fs-delegation"
  service_delegation {
    name    = "Microsoft.DBforMySQL/flexibleServers"
    actions = [
      "Microsoft.Network/virtualNetworks/subnets/join/action",
    ]
  }
}
}

# subnet for container app
resource "azurerm_subnet" "container_subnet" {
  name                 = "subnet-${local.prefix_location}-zenml-container-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/23"]
}

# Virtual Network Peering
# TODO: Uncomment the following block to enable VNet peering
# resource "azurerm_virtual_network_peering" "zenml_vnet_peer" {
#   count = local.use_existing_infra ? 1 : 0
#   name                      = "peer-${local.prefix_location}-zenml-vnet-peer"
#   resource_group_name       = azurerm_resource_group.rg.name
#   virtual_network_name      = azurerm_virtual_network.vnet.name
#   remote_virtual_network_id = local.full_infra_vnet_id
# }


# Zenml Mysql private Zone
resource "azurerm_private_dns_zone" "mysql_zone" {
  count = local.use_existing_infra ? 0 : 1
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

# Zenml Mysql private Zone Link
resource "azurerm_private_dns_zone_virtual_network_link" "mysql_zone_link" {
  name                  = "vnl-${local.prefix_location}-zenmlvnetzone"
  resource_group_name   = try(data.azurerm_resource_group.infra_vnet_rg[0].name,azurerm_resource_group.rg.name)
  private_dns_zone_name = try(data.azurerm_private_dns_zone.infra_mysql_zone[0].name,azurerm_private_dns_zone.mysql_zone[0].name)
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Azure MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = "my-${local.prefix_location}-${var.mysql_server_name}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = var.location
  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
  backup_retention_days  = 7
  delegated_subnet_id    = azurerm_subnet.mysql_subnet.id
  private_dns_zone_id    = data.azurerm_private_dns_zone.infra_mysql_zone[0].id
}

resource "azurerm_mysql_flexible_database" "zenml_db" {
  name                = "zenml"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  collation           = "utf8mb4_unicode_ci"
  charset             = "utf8mb4"
}

# Store Secrets in Key Vault
resource "azurerm_key_vault_secret" "mysql_password" {
  name         = "mysql-password"
  value        = var.mysql_admin_password
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "storage-connection"
  value        = azurerm_storage_account.storage.primary_connection_string
  key_vault_id = azurerm_key_vault.kv.id
}

# Custom Domain for Container App
# resource "azurerm_container_app_custom_domain" "domain" {
#   name                = var.domain_name
#   resource_group_name = azurerm_resource_group.rg.name
#   container_app_id    = azurerm_container_app.zenml_app.id

#   lifecycle {
#     // When using an Azure created Managed Certificate these values must be added to ignore_changes to prevent resource recreation.
#     ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
#   }
# }

# Container App Deployment with ZenML
resource "azurerm_container_app" "zenml_app" {
  name                         = "ca-${local.prefix_location}-${var.container_app_name}"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"
  
  ingress {
    external_enabled = true
    target_port      = 8080
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  secret {
    name  = "mysql-password"
    value = azurerm_key_vault_secret.mysql_password.value
  }

  secret {
    name  = "storage-connection"
    value = azurerm_key_vault_secret.storage_connection_string.value
  }
  

  template {
    container {
      name   = "zenml-server"
      image  = "zenmldocker/zenml-server:0.80.0"
      cpu    = 1
      memory = "2Gi"
      startup_probe {
        timeout       = 5
        port = 8080
        path = "/"
        transport = "HTTP"
        failure_count_threshold = 5
      }
      readiness_probe {
        timeout       = 5
        port = 8080
        path = "/"
        transport = "HTTP"
      }
      liveness_probe {
        initial_delay  = 5
        timeout       = 5
        port = 8080
        path = "/"
        transport = "HTTP"
      }

      env {
        name  = "ZENML_STORE_URL"
        value = "mysql://${var.mysql_admin_username}:${azurerm_key_vault_secret.mysql_password.value}@${azurerm_mysql_flexible_server.mysql.fqdn}:3306/zenml?ssl=true"
      }
      env {
        name  = "ZENML_SERVER_JWT_SECRET_KEY"
        value = var.jwt_secret_key
      }
      env {
        name  = "ZENML_SERVER_AUTO_ACTIVATE"
        value = "1"
      }
      env {
        name  = "ZENML_DEFAULT_USER_NAME"
        value = var.zenml_user_name
      }
      env {
        name  = "ZENML_DEFAULT_USER_PASSWORD"
        value = var.zenml_user_password
      }
    }
  }
  lifecycle {
    ignore_changes = [
      ingress[0].custom_domain
    ]
  }
}
