# If you want access to VPN Pritunl WebUI for example for creating new VPN user:
1. Go to shared/networking/sg.tf
2. Find in ingress sections for #### EC2 VPN Pritunl #### ingress rules
3. Copy existing for example:
```
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

```
4. Change description and change in cidr_blocks parameter to your ip