module "shared" {
  source = "../../modules/route53_zone"

  subzone_name     = var.env
  parent_zone_name = "optimate.online"
  subzone_comment  = "Public zone for ${var.env} resources"

  create_certificate = true

  create_parent_zone_record = false
}
