#########################
#### Security groups ####
#########################
################
#### Shared ####
################
#### RDS MSSQL main ####
resource "aws_security_group" "rds_mssql_main" {
  name = local.rds_mssql_main_name

  description = "Main security group for RDS instance: ${local.rds_mssql_main_name}"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = local.rds_mssql_main_name
  }
}

# Ingress rule #
resource "aws_security_group_rule" "rds_mssql_main_ingress_1" {
  description       = "[T] Allow access to RDS instance: ${local.rds_mssql_main_name}"
  security_group_id = aws_security_group.rds_mssql_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 1433
  to_port   = 1433

  source_security_group_id = aws_security_group.ec2_backend_main.id
}

resource "aws_security_group_rule" "rds_mssql_main_ingress_2" {
  description       = "[T] Allow access from VPN to RDS instance: ${local.rds_mssql_main_name}"
  security_group_id = aws_security_group.rds_mssql_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 1433
  to_port   = 1433

  source_security_group_id = aws_security_group.ec2_vpn_pritunl.id
}


#### EC2 MongoDB main ####
resource "aws_security_group" "ec2_mongodb_main" {
  name = local.ec2_mongodb_main_name

  description = "Main security group for dev EC2 ${local.ec2_mongodb_main_name} instance"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = local.ec2_mongodb_main_name
  }
}

# Egress rule #
resource "aws_security_group_rule" "ec2_mongodb_main_egress_1" {
  description       = "[T] Allow access from EC2 instance: ${local.ec2_mongodb_main_name}"
  security_group_id = aws_security_group.ec2_mongodb_main.id

  type      = "egress"
  protocol  = "-1"
  from_port = 0
  to_port   = 0

  cidr_blocks = ["0.0.0.0/0"]
}

# Ingress rule #
resource "aws_security_group_rule" "ec2_mongodb_main_ingress_1" {
  description       = "[T] Allow access to EC2 instance: ${local.ec2_mongodb_main_name}"
  security_group_id = aws_security_group.ec2_mongodb_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 27017
  to_port   = 27017

  source_security_group_id = aws_security_group.ec2_backend_main.id
}

resource "aws_security_group_rule" "ec2_mongodb_main_ingress_2" {
  description       = "[T] Allow access from VPN to EC2 instance: ${local.ec2_mongodb_main_name}"
  security_group_id = aws_security_group.ec2_mongodb_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 27017
  to_port   = 27017

  source_security_group_id = aws_security_group.ec2_vpn_pritunl.id
}

resource "aws_security_group_rule" "ec2_mongodb_main_ingress_3" {
  description       = "[T] Allow SSH from VPN to EC2 instance: ${local.ec2_mongodb_main_name}"
  security_group_id = aws_security_group.ec2_mongodb_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 22
  to_port   = 22

  source_security_group_id = aws_security_group.ec2_vpn_pritunl.id
}


#### EC2 VPN Pritunl ####
resource "aws_security_group" "ec2_vpn_pritunl" {
  name = local.ec2_vpn_pritunl_name

  description = "Main security group for EC2 instance: ${local.ec2_vpn_pritunl_name}"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = local.ec2_vpn_pritunl_name
  }
}

# Egress rule #
resource "aws_security_group_rule" "ec2_vpn_pritunl_egress_1" {
  description       = "[T] Allow access from EC2 instance: ${local.ec2_vpn_pritunl_name}"
  security_group_id = aws_security_group.ec2_vpn_pritunl.id

  type      = "egress"
  protocol  = "-1"
  from_port = 0
  to_port   = 0

  cidr_blocks = ["0.0.0.0/0"]
}

# Ingress rule #
resource "aws_security_group_rule" "ec2_vpn_pritunl_ingress_1" {
  description       = "[T] Allow access from Internet to VPN: ${local.ec2_vpn_pritunl_name}"
  security_group_id = aws_security_group.ec2_vpn_pritunl.id

  type      = "ingress"
  protocol  = "udp"
  from_port = 19750
  to_port   = 19750

  cidr_blocks = ["0.0.0.0/0"]
}


# This rule allow users get access to VPN Pritunl WebUI
resource "aws_security_group_rule" "ec2_vpn_pritunl_ingress_2" {
  description       = "[T] Allow access from Internet to VPN WEB UI: ${local.ec2_vpn_pritunl_name} for devops"
  security_group_id = aws_security_group.ec2_vpn_pritunl.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  cidr_blocks = ["95.134.30.161/32"]
}


#######################
#### Workload ENVS ####
#######################
#### EC2 backend main ####
resource "aws_security_group" "ec2_backend_main" {
  name = local.ec2_backend_main_name

  description = "Main security group for EC2 instance: ${local.ec2_backend_main_name}"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = local.ec2_backend_main_name
  }
}

# Egress rule #
resource "aws_security_group_rule" "ec2_backend_main_egress_1" {
  description       = "[T] Allow access from EC2 instance: ${local.ec2_backend_main_name}"
  security_group_id = aws_security_group.ec2_backend_main.id

  type      = "egress"
  protocol  = "-1"
  from_port = 0
  to_port   = 0

  cidr_blocks = ["0.0.0.0/0"]
}

# Ingress rule #
resource "aws_security_group_rule" "ec2_backend_main_ingress_1" {
  description       = "[T] Allow access from ${local.ec2_frontend_main_name} to ${local.ec2_backend_main_name}"
  security_group_id = aws_security_group.ec2_backend_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 0
  to_port   = 65535

  source_security_group_id = aws_security_group.ec2_frontend_main.id
}

resource "aws_security_group_rule" "ec2_backend_main_ingress_2" {
  description       = "[T] Allow access from ${local.ec2_static_main_name} to ${local.ec2_backend_main_name}"
  security_group_id = aws_security_group.ec2_backend_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 0
  to_port   = 65535

  source_security_group_id = aws_security_group.ec2_static_main.id
}

resource "aws_security_group_rule" "ec2_backend_main_ingress_3" {
  description       = "[T] Allow access from VPN to ${local.ec2_backend_main_name}"
  security_group_id = aws_security_group.ec2_backend_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 0
  to_port   = 65535

  source_security_group_id = aws_security_group.ec2_vpn_pritunl.id
}

resource "aws_security_group_rule" "ec2_backend_main_ingress_4" {
  description       = "[T] Allow access from ALB to ${local.ec2_backend_main_name}"
  security_group_id = aws_security_group.ec2_backend_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 0
  to_port   = 65535

  source_security_group_id = aws_security_group.alb_main.id
}

resource "aws_security_group_rule" "ec2_backend_main_ingress_5" {
  description       = "[T] Allow SMTPS from ALB to ${local.ec2_backend_main_name}"
  security_group_id = aws_security_group.ec2_backend_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 465
  to_port   = 465

  source_security_group_id = aws_security_group.alb_main.id
}


#### EC2 frontend main ####
resource "aws_security_group" "ec2_frontend_main" {
  name = local.ec2_frontend_main_name

  description = "Main security group for EC2 instance: ${local.ec2_frontend_main_name}"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = local.ec2_frontend_main_name
  }
}

# Egress rule #
resource "aws_security_group_rule" "ec2_frontend_main_egress_1" {
  description       = "[T] Allow access from EC2 instance: ${local.ec2_frontend_main_name}"
  security_group_id = aws_security_group.ec2_frontend_main.id

  type      = "egress"
  protocol  = "-1"
  from_port = 0
  to_port   = 0

  cidr_blocks = ["0.0.0.0/0"]
}

# Ingress rule #
resource "aws_security_group_rule" "ec2_frontend_main_ingress_1" {
  description       = "[T] Allow access from ALB: ${local.alb_main_name} to EC2 instance: ${local.ec2_frontend_main_name}"
  security_group_id = aws_security_group.ec2_frontend_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 0
  to_port   = 65535

  source_security_group_id = aws_security_group.alb_main.id
}

resource "aws_security_group_rule" "ec2_frontend_main_ingress_2" {
  description       = "[T] Allow access from VPN to EC2 instance: ${local.ec2_frontend_main_name}"
  security_group_id = aws_security_group.ec2_frontend_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 0
  to_port   = 65535

  source_security_group_id = aws_security_group.ec2_vpn_pritunl.id
}


#### EC2 static main ####
resource "aws_security_group" "ec2_static_main" {
  name = local.ec2_static_main_name

  description = "Main security group for EC2 instance: ${local.ec2_static_main_name}"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = local.ec2_static_main_name
  }
}

# Egress rule #
resource "aws_security_group_rule" "ec2_static_main_egress_1" {
  description       = "[T] Allow access from EC2 instance: ${local.ec2_static_main_name}"
  security_group_id = aws_security_group.ec2_static_main.id

  type      = "egress"
  protocol  = "-1"
  from_port = 0
  to_port   = 0

  cidr_blocks = ["0.0.0.0/0"]
}

# Ingress rule #
resource "aws_security_group_rule" "ec2_static_main_ingress_1" {
  description       = "[T] Allow access from ALB: ${local.alb_main_name} to EC2 instance: ${local.ec2_static_main_name}"
  security_group_id = aws_security_group.ec2_static_main.id

  type      = "ingress"
  protocol  = "-1"
  from_port = 0
  to_port   = 0

  source_security_group_id = aws_security_group.alb_main.id
}

resource "aws_security_group_rule" "ec2_static_main_ingress_2" {
  description       = "[T] Allow access from ALB: ${local.alb_main_name} to EC2 instance: ${local.ec2_static_main_name}"
  security_group_id = aws_security_group.ec2_static_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 0
  to_port   = 65535

  source_security_group_id = aws_security_group.ec2_vpn_pritunl.id
}


#### ALB main ####
resource "aws_security_group" "alb_main" {
  name = local.alb_main_name

  description = "Main security group for ALB: ${local.alb_main_name}"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = local.alb_main_name
  }
}

# Egress rule #
resource "aws_security_group_rule" "alb_main_egress_1" {
  description       = "[T] Allow access from ALB: ${local.alb_main_name}"
  security_group_id = aws_security_group.alb_main.id

  type      = "egress"
  protocol  = "-1"
  from_port = 0
  to_port   = 0

  cidr_blocks = ["0.0.0.0/0"]
}

# Ingress rule #
resource "aws_security_group_rule" "alb_main_ingress_1" {
  description       = "[T] Allow HTTS trafic from Internet to ALB: ${local.alb_main_name}"
  security_group_id = aws_security_group.alb_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_main_ingress_2" {
  description       = "[T] Allow HTT trafic from Internet to ALB: ${local.alb_main_name}"
  security_group_id = aws_security_group.alb_main.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  cidr_blocks = ["0.0.0.0/0"]
}