resource "random_id" "rg_name" {
  byte_length = 8
}

resource "azurerm_resource_group" "example" {
  location = var.location
  name     = "azure-subnets-${random_id.rg_name.hex}-rg"
}

locals {
  subnets = {
    for i in range(3) :
    "subnet${i}" => {
      address_prefixes = [cidrsubnet(local.virtual_network_address_space, 8, i)]
      route_table = {
        id = azurerm_route_table.example.id
      }
    }
  }
  virtual_network_address_space = "10.0.0.0/16"
}

module "vnet" {
  source = "../../"

  resource_group_name           = azurerm_resource_group.example.name
  subnets                       = local.subnets
  virtual_network_address_space = [local.virtual_network_address_space]
  virtual_network_location      = azurerm_resource_group.example.location
  virtual_network_name          = "azure-subnets-vnet"
}

resource "azurerm_route_table" "example" {
  location            = azurerm_resource_group.example.location
  name                = "MyRouteTable"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_route" "example" {
  address_prefix      = local.virtual_network_address_space
  name                = "acceptanceTestRoute1"
  next_hop_type       = "VnetLocal"
  resource_group_name = azurerm_resource_group.example.name
  route_table_name    = azurerm_route_table.example.name
}