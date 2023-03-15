locals {
  subnet_with_nat_gateway = {
    for name, subnet in var.subnets :
    name => subnet.nat_gateway.id
    if subnet.nat_gateway != null
  }
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
