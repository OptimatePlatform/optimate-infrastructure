module "ec2_static_main" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  name = "${var.env}-${data.terraform_remote_state.networking.outputs.ec2_static_main_name}"

  instance_type = "t2.micro"
  ami           = "ami-023adaba598e661ac" # ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20240301

  # User data
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install -y wget unzip curl apt-transport-https
              curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
              sudo apt install -y nodejs
              sudo npm install pm2 -g
              sudo npm install serve -g
              ### Install AWS cli ###
              sudo curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
              sudo unzip awscliv2.zip
              sudo aws/install
              sudo rm -rf awscliv2.zip aws /usr/local/aws-cli/v2/*/dist/aws_completer /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index /usr/local/aws-cli/v2/*/dist/awscli/examples
              sudo mkdir -p /home/ubuntu/app # create app folder for CICD
              EOF

  # Networking
  vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.ec2_static_main_sg_id]
  availability_zone      = element(data.terraform_remote_state.networking.outputs.azs, 0)
  subnet_id              = element(data.terraform_remote_state.networking.outputs.private_subnets, 0)

  # IAM
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance: ${var.env}-${data.terraform_remote_state.networking.outputs.ec2_static_main_name}"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    S3ReadAccess                 = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  }

  # EBS
  root_block_device = [
    {
      volume_type = "gp3"
      throughput  = 200
      volume_size = 20
    }
  ]
}

# resource "aws_lb_target_group_attachment" "ec2_static_main" {
#   target_group_arn = aws_lb_target_group.static.arn
#   target_id        = module.ec2_static_main.id
#   port             = 3000
# }