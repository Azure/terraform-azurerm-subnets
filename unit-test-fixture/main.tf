variable "azurerm_subnets" {
  type = map(string)
}

locals {
  azurerm_subnet_name2id = var.azurerm_subnets
}

data "null_data_source" "azurerm_subnet_network_security_group_association" {
  for_each = local.subnet_with_network_security_group

  inputs = {
    network_security_group_id = each.value
    subnet_id                 = local.azurerm_subnet_name2id[each.key]
  }
}

data "null_data_source" "azurerm_subnet_route_table_association" {
  for_each = local.subnets_with_route_table

  inputs = {
    route_table_id = each.value
    subnet_id      = local.azurerm_subnet_name2id[each.key]
  }
}

data "null_data_source" "azurerm_subnet_nat_gateway_association" {
  for_each = local.subnet_with_nat_gateway

  inputs = {
    nat_gateway_id = each.value
    subnet_id      = local.azurerm_subnet_name2id[each.key]
  }
}