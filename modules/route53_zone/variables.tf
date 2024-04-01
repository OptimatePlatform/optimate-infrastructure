# ================== #
# Required variables #
# ================== #
variable "subzone_name" {
  description = "Subzone name. Used for creating recors and in forming full zone name"
  type        = string
}

variable "subzone_comment" {
  description = "Description for subzone"
  type        = string
}

variable "parent_zone_name" {
  description = "Parent zone name, where will be created record with name servers for subzone"
  type        = string
}


# ================== #
# Optional variables #
# ================== #
variable "create_parent_zone_record" {
  description = "(Mandatory-Optional) Create NS record in parent zone"
  type        = bool
}

variable "records" {
  description = "List of obects with records"
  type        = any
  default     = []
}

variable "zone_tags" {
  description = "Additional tags for the zone"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}


variable "zone_type" {
  description = "Type of zone. Public or Private (used VPC)"
  type        = string
  default     = "public"
}

variable "vpc_ids" {
  description = "A map of VPC ids for private zone"
  type        = list(any)
  default     = []
}


variable "create_certificate" {
  description = "Create ACM certificate"
  type        = bool
  default     = false
}

variable "custom_zone_name" {
  description = "Custom name for Route53 Hosted zone"
  type        = string
  default     = null
}