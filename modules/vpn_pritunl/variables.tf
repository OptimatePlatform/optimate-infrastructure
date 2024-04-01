# ================== #
# Required variables #
# ================== #
variable "env" {
  type = string
}

variable "vpn_name" {
  type = string
}

variable "vpn_pritunl_security_group_id" {
  description = "Security group id for the VPN Pritunl instance"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets ids for the VPN instance"
  type        = list(string)
}

variable "route53_zone_id" {
  description = "Route53 zone id"
  type        = string
}

# ================== #
# Optional variables #
# ================== #
variable "ami_id" {
  description = "Ami for EC2 instance"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type for VPN instance"
  type        = string
  default     = "t2.micro"
}

variable "volume_size" {
  description = "EC2 volume size"
  type        = string
  default     = "20"
}

variable "custom_vpn_endpoint" {
  description = "Custom name for VPN endpoint (route53 record)"
  type        = string
  default     = ""
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

variable "secret_recovery_window_in_days" {
  description = "Number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30"
  type        = number
  default     = 0
}