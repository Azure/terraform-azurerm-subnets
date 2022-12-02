output "azurerm_subnet_network_security_group_association" {
  value = data.null_data_source.azurerm_subnet_network_security_group_association
}

output "azurerm_subnet_route_table_association" {
  value = data.null_data_source.azurerm_subnet_route_table_association
}

output "azurerm_subnet_nat_gateway_association" {
  value = data.null_data_source.azurerm_subnet_nat_gateway_association
}