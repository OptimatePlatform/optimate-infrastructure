resource "tls_private_key" "ssh" {
  algorithm   = var.algorithm
  rsa_bits    = var.rsa_bits
  ecdsa_curve = var.ecdsa_curve
}

resource "aws_key_pair" "main" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.ssh.public_key_openssh
}


resource "aws_secretsmanager_secret" "ssh_credentials" {
  name                    = "/${var.env}/ssh/${var.key_pair_name}/ssh-credentials"
  recovery_window_in_days = var.secret_recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "ssh_credentials" {
  secret_id = aws_secretsmanager_secret.ssh_credentials.id
  secret_string = jsonencode({
    algorithm           = var.algorithm
    key_name            = aws_key_pair.main.key_name
    private_key_openssh = tls_private_key.ssh.private_key_openssh
    private_key_pem     = tls_private_key.ssh.private_key_pem
    public_key_openssh  = tls_private_key.ssh.public_key_openssh
    public_key_pem      = tls_private_key.ssh.public_key_pem
  })
}