# This configuration file is intended to deploy all azure infrastructure resources for moodle application and it deploys the following:
# 1- resource group for moodle resources
# 2- virtual network with 3 subnets (appgw , vmss , netapp)
# 3- azure mysql server
# 4- netapp account , pool , volume
# 5- ubuntu virtual machine (application server) 
# 5- azure cache for redis instance

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = "b783a142-5c73-49cb-a760-885ef5302414"
  client_secret   = var.client_secret
  tenant_id       = "bee93bf4-cb8e-49bf-a074-95de74673a3d"
}

# resource group 
resource "azurerm_resource_group" "rg" {
  name     = "${var.rg_name}-resources"
  location = var.location
}

# Networking resources

resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg-name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["${var.vnet_address_space}"]

}
resource "azurerm_subnet" "vmss" {
  name                 = var.vmss_subnet
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${var.vmss_subnet_addr}"]

}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.vmss.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "netapp" {
  name                 = var.netapp_subnet
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${var.netapp_subnet_addr}"]

  delegation {
    name = "netapp"

    service_delegation {
      name    = "Microsoft.Netapp/volumes"
      actions = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "appgw" {
  name                 = var.appgw_subnet
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${var.appgw_subnet_addr}"]

}

#  Mysql server

resource "azurerm_mysql_server" "mysql" {
  name                = var.mysql_server_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  administrator_login          = var.mysql_admin_login
  administrator_login_password = var.mysql_admin_password

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "8.0"

  auto_grow_enabled                 = true
  backup_retention_days             = 35
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = false
  #ssl_minimal_tls_version_enforced  = "TLS1_2"
}

# ubuntu virtual machine

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vmss.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm-pip.id
  }
}

resource "azurerm_public_ip" "vm-pip" {
  name                    = "vm-pip"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

}

resource "azurerm_public_ip" "appgw-pip" {
  name                    = "appgw-pip"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

}
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.vm_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_D2s_v4"
  admin_username                  = "moodle"
  admin_password                  = "Pa$$w0rd101102!"
  custom_data                     = base64encode("${file("customdata.txt")}")
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }
}

# Netapp account

resource "azurerm_netapp_account" "netapp_account" {
  name                = var.netapp_account_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

}

# Netapp pool

resource "azurerm_netapp_pool" "netapp_pool" {
  name                = var.netapp_account_pool
  account_name        = azurerm_netapp_account.netapp_account.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_level       = "Premium"
  size_in_tb          = 4
}

resource "azurerm_netapp_volume" "netapp_volume" {

  name                = var.netapp_volume_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_netapp_account.netapp_account.name
  pool_name           = azurerm_netapp_pool.netapp_pool.name
  volume_path         = "my-unique-file-path"
  service_level       = "Premium"
  subnet_id           = azurerm_subnet.netapp.id
  protocols           = ["NFSv4.1"]
  storage_quota_in_gb = 100

  export_policy_rule {
    rule_index        = 1
    allowed_clients   = ["0.0.0.0/0"]
    protocols_enabled = ["NFSv4.1"]
    unix_read_only    = false
  }
}

# Application Gateway

locals {
  backend_address_pool_name      = "${azurerm_virtual_network.vnet.name}-be"
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.vnet.name}-http"
  listener_name                  = "${azurerm_virtual_network.vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet.name}-rule01"
}

resource "azurerm_application_gateway" "appgw" {
  name                = var.appgw_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw-pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Enabled"
   # path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "appgw-nic-association" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_application_gateway.appgw.backend_address_pool[0].id
}

# Azure Cache For Redis

# NOTE: the Name used for Redis needs to be globally unique

resource "azurerm_redis_cache" "redis" {
  name                = var.redis_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = true
  # minimum_tls_version = "1.2"

  redis_configuration {}
}

#-------------------------------------------------------------------