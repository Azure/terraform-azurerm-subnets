variable "azurerm_subnets" {
  type = map(string)
}

locals {
  azurerm_subnets = var.azurerm_subnets
}

data "null_data_source" "azurerm_subnet_network_security_group_association" {
  for_each = toset(local.subnet_names_with_network_security_group)

  inputs = {
    network_security_group_id = var.subnets[each.value].network_security_group.id
    subnet_id                 = local.azurerm_subnets[each.value]
  }
}

data "null_data_source" "azurerm_subnet_route_table_association" {
  for_each = toset(local.subnet_names_with_route_table)

  inputs = {
    route_table_id = var.subnets[each.value].route_table.id
    subnet_id      = local.azurerm_subnets[each.value]
  }
}