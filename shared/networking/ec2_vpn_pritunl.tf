module "vpn_pritunl" {
  source = "../../modules/vpn_pritunl"

  vpn_name = local.ec2_vpn_pritunl_name
  env      = var.env
  ami_id   = "ami-023adaba598e661ac" # ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20240301

  vpn_pritunl_security_group_id = aws_security_group.ec2_vpn_pritunl.id
  subnet_ids                    = module.vpc.public_subnets

  route53_zone_id     = module.shared.zone_id
  custom_vpn_endpoint = "vpn"
}