output "private_ips" {
  value = aws_instance.this.*.private_ip
}

output "ec2_instance_id" {
  value = aws_instance.this.*.id
}

output "vpn_endpoint" {
  value = aws_route53_record.one_host.fqdn
}

output "aws_iam_instance_profile_name" {
  value = aws_iam_instance_profile.this.name
}