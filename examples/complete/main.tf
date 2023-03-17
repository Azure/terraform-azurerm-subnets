resource "random_id" "rg_name" {
  byte_length = 8
}

resource "azurerm_resource_group" "example" {
  location = var.location
  name     = "test-${random_id.rg_name.hex}-rg"
}

resource "azurerm_network_security_group" "nsg1" {
  location            = var.vnet_location
  name                = "test-${random_id.rg_name.hex}-nsg"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_route_table" "rt1" {
  location            = var.vnet_location
  name                = "test-${random_id.rg_name.hex}-rt"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_network_ddos_protection_plan" "example" {
  location            = var.vnet_location
  name                = "example-protection-plan"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_nat_gateway" "example" {
  location            = var.vnet_location
  name                = "example-natgateway"
  resource_group_name = azurerm_resource_group.example.name
}

module "vnet" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.example.name
  subnets = {
    subnet0 = {
      address_prefixes                          = ["10.0.0.0/24"]
      private_endpoint_network_policies_enabled = false
      service_endpoints = [
        "Microsoft.Storage", "Microsoft.Sql"
      ]
      delegations = [
        {
          name = "Microsoft.Sql.managedInstances"
          service_delegation = {
            name = "Microsoft.Sql/managedInstances"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action",
              "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
              "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
            ]
          }
        }
      ]
    }
    subnet1 = {
      address_prefixes                          = ["10.0.1.0/24"]
      private_endpoint_network_policies_enabled = false
      service_endpoints                         = ["Microsoft.AzureActiveDirectory"]
    }
    subnet2 = {
      address_prefixes = ["10.0.2.0/24"]
      nat_gateway = {
        id = azurerm_nat_gateway.example.id
      }
      network_security_group = {
        id = azurerm_network_security_group.nsg1.id
      }
      route_table = {
        id = azurerm_route_table.rt1.id
      }
    }
  }
  virtual_network_dns_servers = {
    dns_servers = ["8.8.8.8"]
  }
  virtual_network_ddos_protection_plan = {
    id     = azurerm_network_ddos_protection_plan.example.id
    enable = true
  }
  virtual_network_address_space = ["10.0.0.0/16"]
  virtual_network_location      = azurerm_resource_group.example.location
  virtual_network_name          = "test-vnet"
}