variable "region" {
  description = "AWS region name"
  type        = string
  default     = "eu-central-1"
}

variable "env" {
  description = "The environment name"
  type        = string
  default     = "shared"
}

variable "lamba_runtime" {
  description = "Lambda functions ryntime"
  type        = string
  default     = "python3.11"
}

variable "lambda_architectures" {
  description = "Instruction set architecture for your Lambda function. Valid values are [\"x86_64\"] and [\"arm64\"]."
  type        = list(string)
  default     = ["x86_64"]
}



variable "db_count_per_rds_treshold" {
  description = "Value of the number of databases on the RDS instance after which a new RDS instance must be deployed"
  type        = number
  default     = 25
}

variable "db_count_per_rds_check_rate" {
  description = "How often run check of databases count per latest RDS instance"
  type        = string
  default     = "rate(10 minutes)"
}

variable "rds_instance_status_polling_frequency" {
  description = "Frequency of polling RDS instance status. Value in seconds"
  type        = number
  default     = 300
}

