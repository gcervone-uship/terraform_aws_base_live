#
# Remote state for the resources in ml-aws-shared/us-east-1/shared (The main shared account)
# VPC Peering to the main shared VPC in this account is done by all other accounts.
#
data "terraform_remote_state" "shared_us_east_1_remote_state" {
  backend = "s3"

  config {
    # https://s3.console.aws.amazon.com/s3/buckets/ml-sre-terraform-aws-base/?region=us-east-1&tab=overview
    bucket                  = "ml-sre-terraform-aws-base"
    key                     = "ml-aws-shared/us-east-1/shared/terraform.tfstate"
    region                  = "us-east-1"
    shared_credentials_file = "../../../common/credentials"
    profile                 = "terraform_shared"
  }

  # Defaults for the remote state.  Necessary for the initial 'shared' creation not to error because this doesn't exist.
  defaults {
    vpc_id     = "undefined"
    account_id = "undefined"
    region     = "undefined"
  }
}

#
# Multiple providers are defined here for ease of reference when performing cross account acctions such
# as subdomaining or vpc peering.
#

provider "aws" {
  alias                   = "shared-us-west-1"
  version                 = "~> 1.10"
  allowed_account_ids     = ["652911386828"]
  region                  = "us-west-1"
  shared_credentials_file = "../../../common/credentials"
  profile                 = "terraform_shared"
}

provider "aws" {
  alias                   = "shared-us-east-1"
  version                 = "~> 1.10"
  allowed_account_ids     = ["652911386828"]
  region                  = "us-east-1"
  shared_credentials_file = "../../../common/credentials"
  profile                 = "terraform_shared"
}

#
# Setup a few datasources for outputs
#
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

##############################################################################
#                                                                            #
#                             VPC PEERING SETUP                              #
#                                                                            #
##############################################################################

#
# Setup vpc peering between the VPC created here and the main one in the shared account.
#
module "vpc_peer" {
  source = "git::https://bitbucket.org/mnv_tech/terraform_aws_base.git//vpc_peering?ref=lee/working" # todo change branch.

  enable_vpc_peering = "${local.enable_vpc_peering}"

  providers = {
    "aws.peer" = "aws.shared-us-east-1" # defined in global.tf
    "aws"      = "aws"                  # defined locally
  }

  my_vpcid          = "${module.vpc.vpc_id}"
  peer_vpcid        = "${data.terraform_remote_state.shared_us_east_1_remote_state.vpc_id}"
  peer_vpc_owner_id = "${data.terraform_remote_state.shared_us_east_1_remote_state.account_id}"
  peer_vpc_region   = "${data.terraform_remote_state.shared_us_east_1_remote_state.region}"

  my_vpc_cidr_block = "${module.vpc.vpc_cidr_block}"
  peer_vpc_cidr_block = "${data.terraform_remote_state.shared_us_east_1_remote_state.vpc_cidr_block}"
  my_public_route_table_ids = "${module.vpc.public_route_table_ids}"
  my_private_route_table_ids = "${module.vpc.private_route_table_ids}"
  peer_public_route_table_ids = "${data.terraform_remote_state.shared_us_east_1_remote_state.public_route_table_ids}"
  peer_private_route_table_ids = "${data.terraform_remote_state.shared_us_east_1_remote_state.private_route_table_ids}"

  common_tags = "${merge(local.common_tags, map("Name", "to-shared-vpc"))}"
}

#
# Add the default security groups to the VPC created above
#
module "default_security_groups" {
  source = "git::https://bitbucket.org/mnv_tech/terraform_aws_base.git//default_security_groups?ref=lee/working" # todo change branch.

  enable_default_security_groups = "${local.enable_default_security_groups}"

  vpc_id = "${module.vpc.vpc_id}"

  common_tags = "${local.common_tags}"
}

module "subdomain" {
  source = "git::https://bitbucket.org/mnv_tech/terraform_aws_base.git//subdomain?ref=lee/working" # todo change branch.

  enable_subdomain = "${local.enable_subdomain}"

  providers = {
    "aws.maindomain" = "aws.shared-us-east-1" # defined in global.tf
    "aws"            = "aws"                  # defined locally
  }

  maindomain_name  = "mml.cloud."
  subdomain_prefix = "${local.subdomain_prefix}"

  common_tags = "${local.common_tags}"
}

##############################################################################
#                                                                            #
#                         TEMPORARY TEST RESOURCES                           #
#                                                                            #
##############################################################################

#
# Test record for the subdomain.  dig test.<subdomain> should result in 127.0.0.1
#
resource "aws_route53_record" "test_A_record" {
  count   = "${local.enable_test_resources}"
  name    = "test-${module.vpc.vpc_id}"                           # todo need to make this work when called from two regions in the same account.  Add something region specific and add to output.
  type    = "A"
  zone_id = "${module.subdomain.zone_id}"
  ttl     = "30"

  records = ["127.0.0.1"]
}

data "aws_ami" "sre_ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["base-ami-ubuntu-hvm-*"]

  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${data.aws_caller_identity.current.account_id}"]
}

resource "aws_key_pair" "deployer" {
  count   = "${local.enable_test_resources}"

  key_name   = "terraform-test-${module.vpc.vpc_id}"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCKxsW/PNdErfbVn2+1oxtAcLTNqmeDdROuH+CdmOH6c3Hbr5QqY+QMBt8rTqxnG8MUMPCFbrsbgYH+SmiZUTzgFlng864HUGtKG917zKQ+uYYN9iuJ2jJJdy1G+BbyS8cjOua9TFdCPe3OV6PwuZtWeBcN0KTkSxzaZBN1U09wLLrpp6MRmC38iss9dsl57QOHa/fkyTxFWm9Mi+1BSCsBWsDR6CeHwmXX/GLOf5eM5NNp210nkLqRBnY5DTETXn6yERf+oAeRBDn0teVD//Vs0N0OZKzKZzaIeesiPQg0JZAOcMMD7AaTJvqC+ZPfGAO+rhXMeRjboBsHGxbxqG2x ml-infra-dev"
}

resource "aws_instance" "test_instance" {
  count   = "${local.enable_test_resources}"

  ami           = "${data.aws_ami.sre_ubuntu.id}"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ "${module.default_security_groups.private_nets_ssh_security_group_id}"]

  key_name = "${aws_key_pair.deployer.key_name}"

  # since I don't have a way into the VPC yet... put it in public and get a public IP.
  subnet_id = "${element(module.vpc.public_subnets, 0)}"
  associate_public_ip_address = true

  tags = "${merge(local.common_tags, map("Name", "terraform-test-${module.vpc.vpc_id}"))}"
}
##############################################################################
#                                                                            #
#                                 OUTPUTS                                    #
#                                                                            #
##############################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${module.vpc.vpc_id}"
}

output "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  value = "${module.vpc.vpc_cidr_block}"
}
output "account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}

output "region" {
  value = "${data.aws_region.current.id}"
}

output "test_DNS_A_Record" {
  value = "dig +short ${aws_route53_record.test_A_record.0.fqdn}"
}

output "test_SSH_Host" {
  value = "ssh -i ~/.ssh/ml-infra-dev.pem ubuntu@${aws_instance.test_instance.0.public_ip}"
}