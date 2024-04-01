data "aws_availability_zones" "available" {}

locals {
  azs = var.azs == null ? slice(data.aws_availability_zones.available.names, 0, 3) : var.azs
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.7.0"

  name = var.vpc_name
  cidr = var.cidr

  azs = local.azs

  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets

  enable_ipv6 = var.enable_ipv6

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az


  public_subnet_tags   = var.public_subnet_tags
  private_subnet_tags  = var.private_subnet_tags
  database_subnet_tags = var.database_subnet_tags

  private_route_table_tags = var.private_route_table_tags
  public_route_table_tags  = var.public_route_table_tags

  nat_eip_tags     = var.nat_eip_tags
  nat_gateway_tags = var.nat_gateway_tags

  vpc_tags = var.vpc_tags
  igw_tags = var.igw_tags

  tags = var.tags
}
