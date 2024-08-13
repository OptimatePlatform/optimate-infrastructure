module "mssql" {
  source = "../../modules/rds_mssql"

  mssql_name = data.terraform_remote_state.networking.outputs.rds_mssql_main_name

  env = var.env

  database_subnet_group = data.terraform_remote_state.networking.outputs.database_subnet_group
  mssql_security_group  = data.terraform_remote_state.networking.outputs.shared_rds_mssql_main_sg_id

  route53_zone_id = data.terraform_remote_state.networking.outputs.route53_zone_id

  deletion_protection = true
}


module "mssql_2" {
  source = "../../modules/rds_mssql"

  mssql_name = "${data.terraform_remote_state.networking.outputs.rds_mssql_main_name}-2"

  env = var.env

  database_subnet_group = data.terraform_remote_state.networking.outputs.database_subnet_group
  mssql_security_group  = data.terraform_remote_state.networking.outputs.shared_rds_mssql_main_sg_id

  route53_zone_id = data.terraform_remote_state.networking.outputs.route53_zone_id

  deletion_protection = true
}
