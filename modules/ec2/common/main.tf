module "ec2" {
  source = ""

  name          = var.ec2_name
  instance_type = var.instance_type

  iam_role_name = aws_iam_role.this.name

  # Network
  availability_zone = var.availability_zone
  subnet_id         = var.subnet_ids[0]

  # Security Groups
  security_groups = concat([var.ec2_security_group], var.additional_security_groups_ids)

  ami = var.ami == "" || var.ami == null ? data.aws_ami.ubuntu.id : var.ami

  # EBS
  ebs_optimized     = var.ebs_optimized
  root_block_device = var.root_block_device
  ebs_block_device  = var.ebs_block_device

  metadata_options = var.metadata_options

  maintenance_options = var.maintenance_options

  timeouts = var.timeouts

  user_data_replace_on_change = var.user_data_replace_on_change

  monitoring = var.monitoring

  key_name = var.key_name

  termination_protection_enabled = var.termination_protection_enabled

  route53_zone_id     = var.route53_zone_id
  route53_custom_name = var.route53_custom_name
  route53_record_type = var.route53_record_type
  route53_record_ttl  = var.route53_record_ttl

  tags = var.tags
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["*ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}