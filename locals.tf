locals {
  subnet_names                             = toset(keys(var.subnets))
  subnet_names_with_network_security_group = keys(local.subnet_with_network_security_group)
  subnet_names_with_route_table            = keys(local.subnets_with_route_table)
  subnet_with_network_security_group = {
    for name, subnet in var.subnets :
    name => subnet.network_security_group.id
    if subnet.network_security_group != null
  }
  subnets_with_route_table = {
    for name, subnet in var.subnets :
    name => subnet.route_table.id
    if subnet.route_table != null
  }
}
