locals {
  zone_name = var.custom_zone_name == null ? "${var.subzone_name}.${var.parent_zone_name}" : var.custom_zone_name
}

module "zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 2.11.1"

  zones = {
    "${local.zone_name}" = {
      comment = var.subzone_comment

      vpc = var.zone_type == "private" ? var.vpc_ids : []

      tags = var.zone_tags
    }
  }

  tags = var.tags
}


module "parent_zone_record" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.11.1"

  create = var.create_parent_zone_record ? true : false

  zone_name = var.parent_zone_name
  records = [
    {
      name    = var.subzone_name
      type    = "NS"
      ttl     = 60
      records = values(module.zones.route53_zone_name_servers)[0]
    }
  ]

  depends_on = [module.zones]
}


module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.11.1"

  create = var.records != [] ? true : false

  zone_name = values(module.zones.route53_zone_name)[0]
  records   = var.records

  depends_on = [module.zones]
}


module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "4.3.2"

  create_certificate = var.create_certificate

  domain_name = values(module.zones.route53_zone_name)[0]
  zone_id     = values(module.zones.route53_zone_zone_id)[0]

  subject_alternative_names = [
    "*.${values(module.zones.route53_zone_name)[0]}",
  ]

  wait_for_validation = true

  tags = var.tags
}