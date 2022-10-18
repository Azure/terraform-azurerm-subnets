locals {
  subnet_names = toset(keys(var.subnets))
}