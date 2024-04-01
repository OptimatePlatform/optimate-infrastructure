output "zone_id" {
  description = "Zone ID of Route53 zone"
  value       = values(module.zones.route53_zone_zone_id)[0]
}

output "zone_name" {
  description = "Name of Route53 zone"
  value       = values(module.zones.route53_zone_name)[0]
}

output "zone_arn" {
  description = "Zone ARN of Route53 zone"
  value       = values(module.zones.route53_zone_zone_arn)[0]
}

output "name_servers" {
  description = "Name servers of Route53 zone"
  value       = values(module.zones.route53_zone_name_servers)[0]
}

output "acm_certificate_arn" {
  description = "Name servers of Route53 zone"
  value       = try(module.acm.acm_certificate_arn, null)
}