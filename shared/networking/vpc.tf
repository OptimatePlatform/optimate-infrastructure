module "vpc" {
  source = "../../modules/vpc"

  env      = var.env
  vpc_name = "${var.env}-vpc"
  cidr     = "10.10.0.0/16"

  public_subnets   = ["10.10.0.0/22", "10.10.4.0/22", "10.10.8.0/22"]
  private_subnets  = ["10.10.128.0/20", "10.10.144.0/20", "10.10.160.0/20"]
  database_subnets = ["10.10.48.0/22", "10.10.52.0/22", "10.10.56.0/22"]

  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}