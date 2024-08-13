

module "mssql" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.8.0"

  identifier = var.mssql_name

  engine               = var.engine
  engine_version       = var.engine_version
  family               = var.family               # DB parameter group
  major_engine_version = var.major_engine_version # DB option group
  port                 = var.port
  instance_class       = var.instance_class
  license_model        = "license-included"

  # Storage
  storage_type          = var.storage_type
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = var.storage_encrypted

  # Credentials
  username                    = var.username
  password                    = random_password.db_password.result
  manage_master_user_password = false

  multi_az = var.multi_az

  # Subnet Group
  create_db_subnet_group      = var.create_db_subnet_group
  db_subnet_group_name        = var.create_db_subnet_group ? var.mssql_name : var.database_subnet_group
  db_subnet_group_description = "Subnet group for MSSQL instance ${var.mssql_name}"

  # Security Group
  vpc_security_group_ids = concat([var.mssql_security_group], var.additional_security_groups_ids)

  # Maintenance window
  maintenance_window = var.maintenance_window
  backup_window      = var.backup_window

  # CloudWatch Logs
  enabled_cloudwatch_logs_exports = var.cloudwatch_logs_exports
  create_cloudwatch_log_group     = true

  # Backup
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = true

  deletion_protection = var.deletion_protection
  apply_immediately   = var.apply_immediately

  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  options = var.options

  character_set_name = var.character_set_name

  timezone = var.timezone

  parameters = var.parameters

  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }

  snapshot_identifier = var.snapshot_identifier

  timeouts = var.timeouts

  # CA certificate
  ca_cert_identifier = var.ca_cert_identifier

  tags = var.tags
}


resource "aws_route53_record" "main" {
  zone_id = var.route53_zone_id
  name    = var.mssql_name
  type    = "A"

  alias {
    name                   = module.mssql.db_instance_address
    zone_id                = module.mssql.db_instance_hosted_zone_id
    evaluate_target_health = true
  }
}

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#%&*()-_=+[]:?"
}


module "secrets_manager" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.1.2"

  name        = "/${var.env}/rds/${var.mssql_name}/credentials"
  description = "Secret for RDS instance ${var.mssql_name}"

  recovery_window_in_days = var.secret_recovery_window_in_days
  secret_string = jsonencode({
    username             = module.mssql.db_instance_username,
    password             = random_password.db_password.result,
    engine               = module.mssql.db_instance_engine,
    port                 = module.mssql.db_instance_port,
    host                 = module.mssql.db_instance_address # aws_route53_record.main.fqdn,
    dbInstanceIdentifier = module.mssql.db_instance_identifier
  })
}