output "ec2_public_ip" {
  value = module.ec2.ec2_public_ip
}

output "ec2_private_ip" {
  value = module.ec2.ec2_private_ip
}

output "ec2_endpoint" {
  value = module.ec2.ec2_endpoint
}

output "ec2_id" {
  description = "The ID of the EC2 instance"
  value       = module.ec2.ec2_id
}

output "ec2_arn" {
  description = "The ARN of the EC2 instance"
  value       = module.ec2.ec2_arn
}