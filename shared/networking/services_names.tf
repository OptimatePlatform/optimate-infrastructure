locals {
  # Shared
  ec2_mongodb_main_name = "${var.env}-ec2-mongodb-main"
  rds_mssql_main_name   = "${var.env}-rds-mssql-main"

  ec2_vpn_pritunl_name     = "${var.env}-ec2-vpn-pritunl"
  ec2_mattermost_main_name = "${var.env}-ec2-mattermost-main"


  # Workload envs
  ec2_backend_main_name       = "ec2-backend-main"
  ec2_backend_scheduling_name = "ec2-backend-scheduling"
  ec2_frontend_main_name      = "ec2-frontend-main"
  ec2_static_main_name        = "ec2-static-main"

  alb_main_name = "alb-main"
}

# Shared
output "ec2_mongodb_main_name" {
  value = local.ec2_mongodb_main_name
}

output "rds_mssql_main_name" {
  value = local.rds_mssql_main_name
}

output "ec2_vpn_pritunl_name" {
  value = local.ec2_vpn_pritunl_name
}



# Workload envs
output "ec2_backend_main_name" {
  value = local.ec2_backend_main_name
}

output "ec2_backend_scheduling_name" {
  value = local.ec2_backend_scheduling_name
}

output "ec2_frontend_main_name" {
  value = local.ec2_frontend_main_name
}

output "ec2_static_main_name" {
  value = local.ec2_static_main_name
}

output "alb_main_name" {
  value = local.alb_main_name
}