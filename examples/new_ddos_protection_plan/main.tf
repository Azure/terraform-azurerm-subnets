resource "random_id" "rg_name" {
  byte_length = 8
}

resource "azurerm_resource_group" "example" {
  location = var.location
  name     = "azure-subnets-${random_id.rg_name.hex}-rg"
}

locals {
  subnets = {
    for i in range(3) : "subnet${i}" => {
      address_prefixes = [cidrsubnet(local.virtual_network_address_space, 8, i)]
    }
  }
  virtual_network_address_space = "10.0.0.0/16"
}

module "vnet" {
  source                        = "../../"
  resource_group_name           = azurerm_resource_group.example.name
  subnets                       = local.subnets
  virtual_network_address_space = [local.virtual_network_address_space]
  virtual_network_location      = var.vnet_location
  virtual_network_name          = "azure-subnets-vnet"
  new_network_ddos_protection_plan = {
    name = "ddos-protection-for-asv"
  }
}