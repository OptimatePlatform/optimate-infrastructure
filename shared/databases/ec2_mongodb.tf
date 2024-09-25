module "ec2_mongodb_main" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.0"

  name = data.terraform_remote_state.networking.outputs.ec2_mongodb_main_name


  instance_type = "t2.micro"
  ami           = "ami-022b6d25d6939a999" #MongoDB 6 Community Edition on Ubuntu Server 22 with Support by cloudimg

  # Networking
  vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.shared_ec2_mongodb_main_sg_id]
  availability_zone      = element(data.terraform_remote_state.networking.outputs.azs, 0)
  subnet_id              = element(data.terraform_remote_state.networking.outputs.private_subnets, 0)

  key_name = data.terraform_remote_state.networking.outputs.key_name

  # IAM
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance: ${data.terraform_remote_state.networking.outputs.ec2_mongodb_main_name}"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # EBS
  root_block_device = [
    {
      volume_type = "gp3"
      throughput  = 200
      volume_size = 50
    }
  ]
}

resource "random_password" "admin_mongo_user" {
  length           = 16
  special          = true
  override_special = "!#%&*()-_=+[]<>"
}

resource "aws_route53_record" "shared_ec2_mongodb_main" {
  name    = data.terraform_remote_state.networking.outputs.ec2_mongodb_main_name
  type    = "A"
  zone_id = data.terraform_remote_state.networking.outputs.route53_zone_id
  ttl     = 60

  records = [module.ec2_mongodb_main.private_ip]
}


module "secrets_manager" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.1.2"

  name        = "/${var.env}/ec2/${data.terraform_remote_state.networking.outputs.ec2_mongodb_main_name}/credentials"
  description = "Secret for EC2 instance: ${data.terraform_remote_state.networking.outputs.ec2_mongodb_main_name}"

  recovery_window_in_days = 0
  secret_string = jsonencode({
    username = "admin"
    password = random_password.admin_mongo_user.result
    port     = 27017
    host     = aws_route53_record.shared_ec2_mongodb_main.fqdn
  })
}

# Mongo configuration
resource "null_resource" "mongo_configuration" {
  provisioner "file" {
    content = templatefile("./templates/ec2_mongodb_user_data.sh.tmpl", {
      admin_password = random_password.admin_mongo_user.result
    })
    destination = "/tmp/mongo_config.sh"

    connection {
      type        = "ssh"
      host        = module.ec2_mongodb_main.private_ip
      user        = "ec2-user"
      private_key = data.terraform_remote_state.networking.outputs.private_key_openssh
    }
  }

  # Script executing
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/mongo_config.sh",
      "sudo bash /tmp/mongo_config.sh",
    ]

    connection {
      type        = "ssh"
      host        = module.ec2_mongodb_main.private_ip
      user        = "ec2-user"
      private_key = data.terraform_remote_state.networking.outputs.private_key_openssh
    }
  }
}