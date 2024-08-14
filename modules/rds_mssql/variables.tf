# ================== #
# Required variables #
# ================== #
variable "mssql_name" {
  description = "The name of RDS instance"
  type        = string
}

variable "env" {
  description = "The environment name"
  type        = string
}

variable "route53_zone_id" {
  type = string
}

variable "mssql_security_group" {
  type = string
}


# ================== #
# Optional variables #
# ================== #
variable "instance_class" {
  type    = string
  default = "db.t3.small"
}

variable "port" {
  type    = number
  default = 1433
}

variable "engine" {
  type    = string
  default = "sqlserver-ex"
}

variable "major_engine_version" {
  type    = string
  default = "16.00"
}

variable "engine_version" {
  type    = string
  default = "16.00.4105.2.v1"
}

variable "family" {
  type    = string
  default = "sqlserver-ex-16.0"
}

variable "license_model" {
  type    = string
  default = "license-included"
}

variable "cloudwatch_logs_exports" {
  type    = list(string)
  default = ["error"]
}

variable "parameters" {
  description = "Object with Microsoft SQL parameters for parameter group"
  type        = any
  default     = []
}

variable "options" {
  description = "Object with  Microsoft SQL options for option group"
  type        = any
  default     = []
}

variable "db_option_group_tags" {
  type = map(any)
  default = {
    "Sensitive" = "low"
  }
}

variable "db_parameter_group_tags" {
  type = map(any)
  default = {
    "Sensitive" = "low"
  }
}

# Storage
# For an RDS instance with storage_type using gp3, be aware that iops and storage_throughput cannot be specified if the allocated_storage value is below a per-engine threshold.
# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html#gp3-storage
variable "storage_type" {
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), 'gp3' (new generation of general purpose SSD), or 'io1' (provisioned IOPS SSD). The default is 'io1' if iops is specified, 'gp2' if not. If you specify 'io1' or 'gp3' , you must also include a value for the 'iops' parameter"
  type        = string
  default     = "gp3"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 50
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "storage_encrypted" {
  type    = bool
  default = false
}

variable "backup_retention_period" {
  type    = number
  default = 1
}

variable "deletion_protection" {
  description = "The database can't be deleted when this value is set to true"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}


variable "additional_security_groups_ids" {
  type    = list(string)
  default = []
}

variable "maintenance_window" {
  type    = string
  default = "Mon:00:00-Mon:03:00"
}

variable "create_db_subnet_group" {
  type    = bool
  default = false
}

variable "database_subnet_group" {
  type    = string
  default = ""
}

variable "backup_window" {
  type    = string
  default = "03:00-06:00"
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  type        = bool
  default     = true
}

variable "character_set_name" {
  description = "The character set name to use for DB encoding in Oracle instances. Changing this parameter causes the RDS instance to be REDEPLOYED. See Oracle Character Sets Supported in Amazon RDS and Collations and Character Sets for Microsoft SQL Server for more information"
  type        = string
  default     = "Latin1_General_CI_AS" # Changing this parameter causes the RDS instance to be REDEPLOYED
}

variable "timezone" {
  description = "Time zone of the DB instance. timezone is currently only supported by Microsoft SQL Server. The timezone can only be set on creation. See MSSQL User Guide for more information"
  type        = string
  default     = "GMT Standard Time" # Changing this parameter causes the RDS instance to be REDEPLOYED
}

variable "username" {
  description = "Username for the master DB user"
  type        = string
  default     = "admin"
}

variable "secret_recovery_window_in_days" {
  description = "Number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30"
  type        = number
  default     = 0
}

variable "snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console, e.g: rds:production-2015-06-26-06-05"
  type        = string
  default     = null
}

variable "timeouts" {
  description = "Updated Terraform resource management timeouts. Applies to `aws_db_instance` in particular to permit resource management times"
  type        = map(string)
  default = {
    create = "1h30m"
    update = "2h"
    delete = "20m"
  }
}

variable "ca_cert_identifier" {
  description = "Specifies the identifier of the CA certificate for the DB instance"
  type        = string
  default     = "rds-ca-rsa2048-g1"
}

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
  default     = {}
}
