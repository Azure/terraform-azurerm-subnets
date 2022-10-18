resource "azurerm_virtual_network" "vnet" {
  address_space           = var.virtual_network_address_space
  location                = var.virtual_network_location
  name                    = var.virtual_network_name
  resource_group_name     = var.resource_group_name
  bgp_community           = var.virtual_network_bgp_community
  edge_zone               = var.virtual_network_edge_zone
  flow_timeout_in_minutes = var.virtual_network_flow_timeout_in_minutes
  tags                    = var.virtual_network_tags

  dynamic "ddos_protection_plan" {
    for_each = var.virtual_network_ddos_protection_plan != null ? [var.virtual_network_ddos_protection_plan] : []

    content {
      enable = ddos_protection_plan.value.enable
      id     = ddos_protection_plan.value.id
    }
  }
}

resource "azurerm_virtual_network_dns_servers" "vnet_dns" {
  count = var.virtual_network_dns_servers == null ? 0 : 1

  virtual_network_id = azurerm_virtual_network.vnet.id
  dns_servers        = var.virtual_network_dns_servers.dns_servers
}

resource "azurerm_subnet" "subnet" {
  for_each = local.subnet_names

  address_prefixes                              = var.subnets[each.value].address_prefixes
  name                                          = each.value
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  private_endpoint_network_policies_enabled     = var.subnets[each.value].private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = var.subnets[each.value].private_link_service_network_policies_enabled
  service_endpoint_policy_ids                   = var.subnets[each.value].service_endpoint_policy_ids
  service_endpoints                             = var.subnets[each.value].service_endpoints

  dynamic "delegation" {
    for_each = var.subnets[each.value].delegations == null ? [] : var.subnets[each.value].delegations

    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }

  # Do not remove this `depends_on` or we'll met a parallel related issue that failed the creation of `azurerm_subnet_route_table_association` and `azurerm_subnet_network_security_group_association`
  depends_on = [azurerm_virtual_network_dns_servers.vnet_dns]
}

locals {
  azurerm_subnets = {
    for index, subnet in azurerm_subnet.subnet :
    subnet.name => subnet.id
  }
}

locals {
  subnet_names_with_network_security_group = keys(local.subnet_with_network_security_group)
  subnet_with_network_security_group = {
    for name, subnet in var.subnets :
    name => subnet.network_security_group.id
    if subnet.network_security_group != null
  }
}

resource "azurerm_subnet_network_security_group_association" "vnet" {
  for_each = toset(local.subnet_names_with_network_security_group)

  network_security_group_id = local.subnet_with_network_security_group[each.value]
  subnet_id                 = local.azurerm_subnets[each.value]
}

locals {
  subnet_names_with_route_table = keys(local.subnets_with_route_table)
  subnets_with_route_table = {
    for name, subnet in var.subnets :
    name => subnet.route_table.id
    if subnet.route_table != null
  }
}

resource "azurerm_subnet_route_table_association" "vnet" {
  for_each = toset(local.subnet_names_with_route_table)

  route_table_id = var.subnets[each.value].route_table.id
  subnet_id      = local.azurerm_subnets[each.value]

  depends_on = [azurerm_subnet_network_security_group_association.vnet]
}