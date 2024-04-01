#############
#### VPC ####
#############
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "azs" {
  description = "A list of availability zones specified as argument to this module"
  value       = module.vpc.azs
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "database_subnet_group" {
  description = "ID of database subnet group"
  value       = module.vpc.database_subnet_group
}


###################
# Security Groups #
###################
################
#### Shared ####
################
#### RDS MSSQL main ####
output "shared_rds_mssql_main_sg_id" {
  value = aws_security_group.rds_mssql_main.id
}

#### EC2 MongoDB main ####
output "shared_ec2_mongodb_main_sg_id" {
  value = aws_security_group.ec2_mongodb_main.id
}


#### EC2 backend main ####
output "ec2_backend_main_sg_id" {
  value = aws_security_group.ec2_backend_main.id
}

#### EC2 frontend main ####
output "ec2_frontend_main_sg_id" {
  value = aws_security_group.ec2_frontend_main.id
}

#### EC2 static main ####
output "ec2_static_main_sg_id" {
  value = aws_security_group.ec2_static_main.id
}

#### ALB main ####
output "alb_main_sg_id" {
  value = aws_security_group.alb_main.id
}

###########
# Route53 #
###########
output "route53_zone_id" {
  description = "Zone ID of Route53 zone"
  value       = module.shared.zone_id
}

output "route53_zone_name" {
  description = "Name of Route53 zone"
  value       = module.shared.zone_name
}

output "route53_zone_arn" {
  description = "Zone ARN of Route53 zone"
  value       = module.shared.zone_arn
}

output "route53_zone_name_servers" {
  description = "Name servers of Route53 zone"
  value       = module.shared.name_servers
}


#######
# SSH #
#######
output "key_name" {
  value = module.ssh.key_name
}

output "private_key_openssh" {
  value     = module.ssh.private_key_openssh
  sensitive = true
}

output "private_key_pem" {
  value     = module.ssh.private_key_pem
  sensitive = true
}


output "ssh_creds_secret_arn" {
  value = module.ssh.ssh_creds_secret_arn
}