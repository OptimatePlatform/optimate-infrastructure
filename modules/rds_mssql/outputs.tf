output "rds_id" {
  value = module.mssql.db_instance_identifier
}

output "rds_arn" {
  value = module.mssql.db_instance_arn
}

# output "rds_host" {
#   value = aws_route53_record.main.fqdn
# }

output "rds_port" {
  value = module.mssql.db_instance_port
}

output "rds_master_user" {
  value     = module.mssql.db_instance_username
  sensitive = true
}

output "rds_master_password" {
  value     = random_password.db_password.result
  sensitive = true
}


# output "secret_arn" {
#   description = "The ARN of the secret where stored RDS instance connection information"
#   value       = module.secrets_manager.secret_arn
# }