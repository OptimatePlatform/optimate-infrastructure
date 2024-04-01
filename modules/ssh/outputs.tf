output "algorithm" {
  value = var.algorithm
}

output "key_name" {
  value = aws_key_pair.main.key_name
}

output "private_key_openssh" {
  value     = tls_private_key.ssh.private_key_openssh
  sensitive = true
}

output "private_key_pem" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}

output "public_key_openssh" {
  value     = tls_private_key.ssh.public_key_openssh
  sensitive = true
}

output "public_key_pem" {
  value     = tls_private_key.ssh.public_key_pem
  sensitive = true
}

output "ssh_creds_secret_arn" {
  value = aws_secretsmanager_secret.ssh_credentials.arn
}