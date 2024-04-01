# ================== #
# Required variables #
# ================== #
variable "ec2_name" {
  type = string
}

variable "ec2_security_group" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance; which can be managed using the `aws_key_pair` resource"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 record zone ID"
  type        = string
}


# ================== #
# Optional variables #
# ================== #

variable "ami" {
  description = "ID of AMI to use for the instance"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t3.micro"
}

variable "availability_zone" {
  description = "AZ to start the instance in"
  type        = string
  default     = null
}

variable "additional_security_groups_ids" {
  type    = list(string)
  default = []
}

# EBS
variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  type        = bool
  default     = false
}

variable "root_block_device" {
  description = "Customize details about the root block device of the instance."
  type        = list(any)
  default     = []
}

variable "ebs_block_device" {
  description = "Additional EBS block devices to attach to the instance"
  type        = list(any)
  default     = []
}


variable "metadata_options" {
  description = "Customize the metadata options of the instance"
  type        = map(string)
  default = {
    "http_endpoint"               = "enabled"
    "http_put_response_hop_limit" = 1
    "http_tokens"                 = "optional"
  }
}

variable "maintenance_options" {
  description = "The maintenance options for the instance"
  type        = any
  default     = {}
}

variable "timeouts" {
  description = "Define maximum timeout for creating, updating, and deleting EC2 instance resources"
  type        = map(string)
  default     = {}
}

variable "user_data_replace_on_change" {
  description = "When used in combination with user_data or user_data_base64 will trigger a destroy and recreate when set to true. Defaults to false if not set"
  type        = bool
  default     = null
}

variable "monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = false
}

variable "termination_protection_enabled" {
  description = "If true, enables EC2 Instance Termination Protection"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}


###### Route53 record ######
variable "route53_custom_name" {
  description = "Custom name for Route53 record that associated with the instance"
  type        = string
  default     = null
}

variable "route53_record_type" {
  description = "The route53 record type"
  type        = string
  default     = "A"
}

variable "route53_record_ttl" {
  description = "The TTL of the route53 record."
  type        = number
  default     = 60
}

variable "node_exporter_version" {
  description = "(Optional) The version of Node Exporter to set up."
  type        = string
  default     = "1.6.0"
}


##########################
# Data lifecycle manager #
##########################
variable "dlm_resource_types" {
  description = "A list of resource types that should be targeted by the lifecycle policy. Valid values are VOLUME and INSTANCE."
  type        = list(string)
  default     = ["INSTANCE"]
}

### Create rule ###

variable "dlm_create_rule_cron_expression" {
  description = "The schedule, as a Cron expression. The schedule interval must be between 1 hour and 1 year. Conflicts with dlm_create_rule_interval, dlm_create_rule_time"
  type        = string
  default     = ""
}


variable "dlm_create_rule_interval" {
  description = "How often this lifecycle policy should be evaluated. 1,2,3,4,6,8,12 or 24 hours are valid values. Conflicts with dlm_create_rule_cron_expression"
  type        = number
  default     = 24

  validation {
    condition     = contains([1, 2, 3, 4, 6, 8, 12, 24], var.dlm_create_rule_interval)
    error_message = "1,2,3,4,6,8,12,24 are valid values for dlm_create_rule_interval"
  }
}

variable "dlm_create_rule_time" {
  description = "Time in 24 hour clock format that sets when the lifecycle policy should be evaluated. Conflicts with dlm_create_rule_cron_expression"
  type        = string
  default     = "23:30"
}

### Retain rule ###
variable "dlm_retain_rule_count" {
  description = "Specifies the number of oldest AMIs to deprecate. Must be an integer between 1 and 1000"
  type        = number
  default     = 15

  validation {
    condition     = var.dlm_retain_rule_count >= 1 && var.dlm_retain_rule_count <= 1000
    error_message = "dlm_retain_rule_count must be an integer between 1 and 1000"
  }
}

variable "dlm_copy_tags" {
  description = "Copy all user-defined tags on a source volume to snapshots of the volume created by this policy."
  type        = bool
  default     = true
}