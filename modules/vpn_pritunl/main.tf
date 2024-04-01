data "aws_partition" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "this" {
  ami           = var.ami_id == "" || var.ami_id == null ? data.aws_ami.ubuntu.id : var.ami_id
  instance_type = var.instance_type

  user_data = templatefile("${path.module}/templates/userdata.sh.tpl",
    {
      credentials_secret = aws_secretsmanager_secret.pritunl_creds.id
    }
  )

  vpc_security_group_ids = [var.vpn_pritunl_security_group_id]

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  iam_instance_profile = aws_iam_instance_profile.this.name

  subnet_id                   = var.subnet_ids[0]
  associate_public_ip_address = true

  disable_api_termination = var.termination_protection_enabled

  tags = merge(
    {
      "Name" = var.vpn_name
    },
    var.tags
  )
}


# -----------------------------
# Pritunl credentials secret
# -----------------------------
resource "time_sleep" "wait_for_updated_secret_value_by_userdata" {
  create_duration = "150s"

  depends_on = [aws_instance.this]
}

resource "aws_secretsmanager_secret" "pritunl_creds" {
  description             = "Secret with all creds related to VPN Pritunl"
  recovery_window_in_days = var.secret_recovery_window_in_days
  name                    = "/${var.env}/vpn/pritunl/${var.vpn_name}/credentials"
}

###### After that userdata update secret value we will get it and merge with new value ######
data "aws_secretsmanager_secret_version" "updated_value_by_ec2_userdata" {
  secret_id = aws_secretsmanager_secret.pritunl_creds.id

  depends_on = [aws_route53_record.one_host, time_sleep.wait_for_updated_secret_value_by_userdata]
}

resource "aws_secretsmanager_secret_version" "credentials" {
  secret_id = aws_secretsmanager_secret.pritunl_creds.id

  secret_string = jsonencode(merge(jsondecode(data.aws_secretsmanager_secret_version.updated_value_by_ec2_userdata.secret_string),
    {
      host = aws_route53_record.one_host.fqdn
    }
  ))
}


resource "aws_eip" "this" {
  instance = aws_instance.this.id
  domain   = "vpc"

  tags = merge({ "Name" = var.vpn_name }, var.tags)
}

# -----------------------------
# Route53
# -----------------------------
resource "aws_route53_record" "one_host" {
  name    = var.custom_vpn_endpoint == "" ? var.vpn_name : var.custom_vpn_endpoint
  type    = "A"
  zone_id = var.route53_zone_id
  ttl     = 60

  records = [aws_eip.this.public_ip]
}
