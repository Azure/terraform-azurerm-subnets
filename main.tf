resource "azurerm_virtual_network" "vnet" {
  address_space           = var.virtual_network_address_space
  location                = var.virtual_network_location
  name                    = var.virtual_network_name
  resource_group_name     = var.resource_group_name
  bgp_community           = var.virtual_network_bgp_community
  edge_zone               = var.virtual_network_edge_zone
  flow_timeout_in_minutes = var.virtual_network_flow_timeout_in_minutes
  tags = merge(var.virtual_network_tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "7dd2356c0d54c2e3d9c7ee48a0caa214e445ad11"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2022-10-18 13:49:51"
    avm_git_org              = "Azure"
    avm_git_repo             = "terraform-azurerm-subnets"
    avm_yor_trace            = "a96b0188-9d1a-43da-b8d2-8026f42d6e8b"
    } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/), (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_yor_name = "vnet"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))

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
  for_each = var.subnets

  address_prefixes                              = each.value.address_prefixes
  name                                          = each.key
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  private_endpoint_network_policies_enabled     = each.value.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  service_endpoint_policy_ids                   = each.value.service_endpoint_policy_ids
  service_endpoints                             = each.value.service_endpoints

  dynamic "delegation" {
    for_each = each.value.delegations == null ? [] : each.value.delegations

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
  azurerm_subnet_name2id = {
    for index, subnet in azurerm_subnet.subnet :
    subnet.name => subnet.id
  }
}

resource "azurerm_subnet_network_security_group_association" "vnet" {
  for_each = local.subnet_with_network_security_group

  network_security_group_id = each.value
  subnet_id                 = local.azurerm_subnet_name2id[each.key]
}

resource "azurerm_subnet_route_table_association" "vnet" {
  for_each = local.subnets_with_route_table

  route_table_id = each.value
  subnet_id      = local.azurerm_subnet_name2id[each.key]
}

resource "azurerm_subnet_nat_gateway_association" "nat_gw" {
  for_each = local.subnet_with_nat_gateway

  nat_gateway_id = each.value
  subnet_id      = local.azurerm_subnet_name2id[each.key]
}