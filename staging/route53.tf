module "route53_zone" {
  source = "../modules/route53_zone"

  subzone_name     = var.env
  parent_zone_name = "optimate.online"
  subzone_comment  = "Main Public zone for ${var.env} env"

  create_certificate = true

  create_parent_zone_record = false
}