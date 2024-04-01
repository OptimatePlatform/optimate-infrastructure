module "ec2_mattermost_main" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  name = local.ec2_mattermost_main_name

  instance_type = "t2.micro"
  ami           = "ami-03ad5947578e878c8"

  key_name = module.ssh.key_name

  # Networking
  vpc_security_group_ids = [aws_security_group.ec2_mattermost_main.id]
  availability_zone      = element(module.vpc.azs, 0)
  subnet_id              = element(module.vpc.private_subnets, 0)

  # IAM
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance: ${local.ec2_mattermost_main_name}"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # EBS
  root_block_device = [
    {
      volume_type = "gp3"
      throughput  = 200
      volume_size = 60
    }
  ]
}
