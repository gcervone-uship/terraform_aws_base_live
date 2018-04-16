locals {
  # Tags applied to all security groups
  sg_tags = {
    role = "openvpn access server security group"
  }

  # Ingress rules applied to all security group.
  # Add ICMP to all rules
  common_ingress_rules = ["all-icmp"]

  # Private security groups allow ingress from these networks
  rfc_1918_private_networks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

  # Public security groups allow ingress from these networks
  all_networks = ["0.0.0.0/0"]
}

module "public_openvpn_security_group" {
  source = "terraform-aws-modules/security-group/aws//modules/openvpn"

  create = true

  name        = "public-openvpn-sg"
  description = "openvpn ports, egress ports are open to all networks"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks    = "${local.all_networks}"
  auto_ingress_with_self = []

  ingress_rules = "${local.common_ingress_rules}"

  tags = "${merge(local.common_tags, local.sg_tags)}"
}

resource "aws_instance" "openvpn_instance" {
  ami                    = "ami-1b9c4966"                                                                                                                        # <<--- Marketplace ami.  need to agree to license in marketplace.
  instance_type          = "t2.small"
  vpc_security_group_ids = ["${module.public_openvpn_security_group.this_security_group_id}", "${module.default_security_groups.private_ssh_security_group_id}"]

  key_name = "${aws_key_pair.deployer.key_name}"

  # since I don't have a way into the VPC yet... put it in public and get a public IP.
  subnet_id                   = "${element(module.vpc.public_subnets, 0)}"
  associate_public_ip_address = true

  tags = "${merge(local.common_tags, map("Name", "OpenVPN Access Server"))}"

  user_data = <<CONFIG
public_hostname=vpn.shared.mml.cloud
admin_pw=ppUkr/BHTNWnqxx99mC2
CONFIG
}

resource "aws_route53_record" "openvpn_dns" {
  name    = "vpn"
  type    = "A"
  zone_id = "${module.subdomain.zone_id}"
  ttl     = "30"

  records = ["${aws_instance.openvpn_instance.public_ip}"]
}

output "OpenVPN URL" {
  value = "https://${aws_route53_record.openvpn_dns.fqdn}"
}
