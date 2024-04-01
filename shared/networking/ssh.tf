

module "ssh" {
  source = "../../modules/ssh"

  key_pair_name = "${var.env}-sshkey-main"

  algorithm = "RSA"
  rsa_bits  = 4096

  env = var.env
}