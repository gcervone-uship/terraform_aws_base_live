# https://openvpn.net/index.php/access-server/docs/admin-guides/381-backing-up-the-access-server.html
# https://openvpn.net/index.php/access-server/docs/admin-guides-sp-859543150/howto-commands/371-access-server-daemon-status-and-control.html

module "public_openvpn_security_group" {
  source = "terraform-aws-modules/security-group/aws//modules/openvpn"

  create = true

  name        = "public-openvpn-sg"
  description = "openvpn ports, egress ports are open to all networks"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks    = ["0.0.0.0/0"]
  auto_ingress_with_self = []

  ingress_rules = ["all-icmp"]

  tags = "${merge(local.common_tags, map("role", "OpenVPN Access Server Security Group"))}"
}

resource "aws_key_pair" "vpn-ssh-keypair" {
  count = "${local.enable_test_resources}"

  key_name = "openvpn-${module.vpc.vpc_id}"

  # ml-sre public key
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbiBbS20rjG5vE9ZI+HiiNIhvtoMCNBjAuyaBFAoFbMu7zHVyhiZwKcpqsreqin8b10PIqqhKfezkbJQawbBiB+p04q4QN0BmJ94yLgiw67xbw/Dgx4McXE9KTk/os1RoDiinyuIDdKEGzR2igCyNcjDJMoSmPOE+UvySZ5TfwNPL9UVhONSB6kJnzwNW9iHP8UF3bw57Q8+XV9XIzxgBpVDt7beOYAH5+Zp7H7Ug1JyiXTjduO7i2NDweQm3ET4T4l5PlNE20uS9/qtVirNIjm+oKTH0MI6OzIYwwKrmJNpMEAwKXSB3mkNHhEVnNB4gMdGVVmLSogJPCql09Np8t ml-sre"
}

resource "aws_eip" "vpn-eip" {
  vpc = true

  instance   = "${aws_instance.openvpn_instance.id}"
  depends_on = ["module.vpc"]

  tags = "${merge(local.common_tags, map("Name", "OpenVPN Access Server EIP"))}"
}

resource "aws_instance" "openvpn_instance" {
  #
  # Marketplace AMI.  Need to agree to license in marketplace before using.
  #
  ami = "ami-1b9c4966"

  instance_type          = "t2.small"
  vpc_security_group_ids = ["${module.public_openvpn_security_group.this_security_group_id}", "${module.default_security_groups.private_ssh_security_group_id}"]

  key_name = "${aws_key_pair.vpn-ssh-keypair.key_name}"

  # since I don't have a way into the VPC yet... put it in public and get a public IP.
  subnet_id                   = "${element(module.vpc.public_subnets, 0)}"
  associate_public_ip_address = true

  tags = "${merge(local.common_tags, map("Name", "OpenVPN Access Server"))}"

  # todo change the public hostname to .sh instead of .shared
  user_data = <<CONFIG
public_hostname=vpn.${module.subdomain.full_subdomain_name}
admin_user=openvpn
admin_pw=${var.vpn_admin_pw}
CONFIG

  # ignore change to user_data as these configs will be changed in running server.
  # effectively means that you can define any new password after it's created and it
  # will have no effect on the already running server.
  lifecycle {
    ignore_changes = ["user_data"]
  }
}

resource "aws_route53_record" "openvpn_dns" {
  name    = "vpn"
  type    = "A"
  zone_id = "${module.subdomain.zone_id}"
  ttl     = "30"

  records = ["${aws_eip.vpn-eip.public_ip}"]
}

variable "vpn_admin_pw" {
  description = "Default password for the openvpn user in the Web UI"
}

output "zz_test_OpenVPN URL" {
  value = "https://${aws_route53_record.openvpn_dns.fqdn}/admin"
}

output "zz_test_OpenVPN SSH Endpoint" {
  value = "ssh -i ~/.ssh/ml-sre.pem openvpnas@${aws_instance.openvpn_instance.private_ip} # Need to connect to VPN first..."
}
