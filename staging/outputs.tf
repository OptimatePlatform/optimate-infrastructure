# Route53
output "route53_zone_id" {
  description = "Zone ID of Route53 zone"
  value       = module.route53_zone.zone_id
}

output "route53_zone_name" {
  description = "Name of Route53 zone"
  value       = module.route53_zone.zone_name
}

output "route53_zone_arn" {
  description = "Zone ARN of Route53 zone"
  value       = module.route53_zone.zone_arn
}

output "route53_zone_name_servers" {
  description = "Name servers of Route53 zone"
  value       = module.route53_zone.name_servers
}

output "route53_zone_acm_certificate_arn" {
  description = "Name servers of Route53 zone"
  value       = module.route53_zone.acm_certificate_arn
}