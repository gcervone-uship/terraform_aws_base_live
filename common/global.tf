####################################################################################################################
####################################################################################################################
##                                                                                                                ##
## THIS FILE CONTAINS CODE COMMON TO ALL ENVIRONMENTS.  IT LIVES IN THE /common DIRECTORY AND SHOULD BE           ##
## SYMBOLICALLY LINKED INTO EACH ENVIRONMENT.  (THERE ARE NO PROVISIONS IN TERRAFORM FOR "INCLUDING" THE FILE.)   ##
##                                                                                                                ##
####################################################################################################################
####################################################################################################################

##############################################################################
#                                                                            #
#                         DATA SOURCES / COMMON PROVIDERS                    #
#                                                                            #
##############################################################################

#
# Remote state for the resources in ml-aws-shared/us-east-1/shared (The main shared account)
# VPC Peering to the main shared VPC in this account is done by all other accounts.
# Subdomaining also involves reading from this central account's state.
#
data "terraform_remote_state" "shared_us_east_1_remote_state" {
  backend = "s3"

  config {
    # https://s3.console.aws.amazon.com/s3/buckets/ml-sre-terraform-aws-base/?region=us-east-1&tab=overview
    bucket                  = "ml-sre-terraform-aws-base"
    key                     = "ml-aws-shared/us-east-1/shared/terraform.tfstate"
    dynamodb_table          = "ml-sre-terraform-aws-base"
    region                  = "us-east-1"
    shared_credentials_file = "../../../common/credentials"
    profile                 = "terraform_shared"
  }

  # Bogus defaults for the remote state datasource when the remote state doesn't yet exist.
  # Necessary for the initial 'shared' creation not to error because that is what creates it.  Chicken/Egg
  defaults {
    vpc_id              = "undefined"
    vpc_cidr_block      = "undefined"
    account_id          = "undefined"
    region              = "undefined"
    Z_Test_DNS_A_Record = "undefined"
    Z_Test_SSH_Host     = "undefined"
  }
}

#
# Provider for the "main" shared configuration in us-east-1.
# THIS SHOULD NOT BE EDITED UNLESS YOU ARE CHANGING THE HUB/SPOKE MODEL OFF OF SHARED.
# Used when performing cross account acctions such as subdomaining or vpc peering.
#

provider "aws" {
  alias                   = "shared-us-east-1"
  version                 = "~> 1.10"
  allowed_account_ids     = ["652911386828"]
  region                  = "us-east-1"
  shared_credentials_file = "../../../common/credentials"
  profile                 = "terraform_shared"
}

##############################################################################
#                                                                            #
#                                 VPC SETUP                                  #
#                                                                            #
##############################################################################

#
# Creates and configures the vpc, subnets, subnet groups, internet gateways and NAT gateways
#
module "vpc" {
  source = "git::https://bitbucket.org/mnv_tech/terraform_aws_base.git//vpc?ref=lee/working" # todo change branch.

  vpc_name                = "${local.vpc_name}"
  vpc_cidr                = "${local.vpc_cidr}"
  vpc_azs                 = "${local.vpc_azs}"
  vpc_private_subnets     = "${local.vpc_private_subnets}"
  vpc_public_subnets      = "${local.vpc_public_subnets}"
  vpc_database_subnets    = "${local.vpc_database_subnets}"
  vpc_elasticache_subnets = "${local.vpc_elasticache_subnets}"
  vpc_redshift_subnets    = "${local.vpc_redshift_subnets}"

  common_tags = "${local.common_tags}"
}

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

  enable_vpc_peering                     = "${local.enable_vpc_peering}"
  enable_vpc_peering_route_table_updates = "${local.enable_vpc_peering_route_table_updates && local.enable_vpc_peering}"

  providers = {
    "aws.peer" = "aws.shared-us-east-1" # defined in this file (global.tf)
    "aws"      = "aws"                  # defined in environment specific tf file (ex. prototype.tf)
  }

  my_vpcid                         = "${module.vpc.vpc_id}"
  my_vpc_cidr_block                = "${module.vpc.vpc_cidr_block}"
  my_public_route_table_ids        = "${module.vpc.public_route_table_ids}"
  my_public_route_table_ids_count  = "${module.vpc.public_route_table_ids_count}"
  my_private_route_table_ids       = "${module.vpc.private_route_table_ids}"
  my_private_route_table_ids_count = "${module.vpc.private_route_table_ids_count}"

  peer_vpc_owner_id                  = "${data.terraform_remote_state.shared_us_east_1_remote_state.account_id}"
  peer_vpc_region                    = "${data.terraform_remote_state.shared_us_east_1_remote_state.region}"
  peer_vpcid                         = "${data.terraform_remote_state.shared_us_east_1_remote_state.vpc_id}"
  peer_vpc_cidr_block                = "${data.terraform_remote_state.shared_us_east_1_remote_state.vpc_cidr_block}"
  peer_public_route_table_ids        = "${data.terraform_remote_state.shared_us_east_1_remote_state.public_route_table_ids}"
  peer_public_route_table_ids_count  = "${data.terraform_remote_state.shared_us_east_1_remote_state.public_route_table_ids_count}"
  peer_private_route_table_ids       = "${data.terraform_remote_state.shared_us_east_1_remote_state.private_route_table_ids}"
  peer_private_route_table_ids_count = "${data.terraform_remote_state.shared_us_east_1_remote_state.private_route_table_ids_count}"

  common_tags = "${merge(local.common_tags, map("Name", "to-shared-vpc"))}"
}

##############################################################################
#                                                                            #
#                             VPC FLOW LOG SETUP                             #
#                                                                            #
##############################################################################
module "vpc_flowlog" {
  source = "git::https://bitbucket.org/mnv_tech/terraform_aws_base.git//vpc_flowlogs?ref=lee/working" # todo change branch.

  enable_vpc_flow_logs = "${local.enable_vpc_flow_logs}"
  common_tags          = "${local.common_tags}"
  vpc_id               = "${module.vpc.vpc_id}"

  retention_in_days = "365"
  traffic_type      = "REJECT"
}

##############################################################################
#                                                                            #
#                          DEFAULT SECURITY GROUPS                           #
#                                                                            #
##############################################################################
module "default_security_groups" {
  source = "git::https://bitbucket.org/mnv_tech/terraform_aws_base.git//default_security_groups?ref=lee/working" # todo change branch.

  enable_default_security_groups = "${local.enable_default_security_groups}"

  vpc_id = "${module.vpc.vpc_id}"

  common_tags = "${local.common_tags}"
}

##############################################################################
#                                                                            #
#                              SUBDOMAIN SETUP                               #
#                                                                            #
##############################################################################

module "subdomain" {
  source = "git::https://bitbucket.org/mnv_tech/terraform_aws_base.git//subdomain?ref=lee/working" # todo change branch.

  enable_subdomain               = "${local.enable_subdomain}"
  enable_subdomain_wildcard_cert = "${local.enable_subdomain_wildcard_cert && local.enable_subdomain}"

  providers = {
    "aws.maindomain" = "aws.shared-us-east-1" # defined in this file (global.tf)
    "aws"            = "aws"                  # defined in environment specific tf file (ex. prototype.tf)
  }

  maindomain_name  = "mml.cloud."
  subdomain_prefix = "${local.subdomain_prefix}"

  common_tags = "${local.common_tags}"
}

##############################################################################
#                                                                            #
#                          OPTIONAL TEST RESOURCES                           #
#                                                                            #
##############################################################################

#
# Test record for the subdomain.  dig test.<subdomain> should result in 127.0.0.1
#
resource "aws_route53_record" "test_A_record" {
  count   = "${local.enable_test_resources}"
  name    = "test-${module.vpc.vpc_id}"      # todo need to make this work when called from two regions in the same account.  Add something region specific and add to output.
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

  owners = ["${data.aws_caller_identity.current.account_id}", "652911386828"]
}

resource "aws_key_pair" "deployer" {
  count = "${local.enable_test_resources}"

  key_name = "terraform-test-${module.vpc.vpc_id}"

  # ml-infra-dev public key
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCKxsW/PNdErfbVn2+1oxtAcLTNqmeDdROuH+CdmOH6c3Hbr5QqY+QMBt8rTqxnG8MUMPCFbrsbgYH+SmiZUTzgFlng864HUGtKG917zKQ+uYYN9iuJ2jJJdy1G+BbyS8cjOua9TFdCPe3OV6PwuZtWeBcN0KTkSxzaZBN1U09wLLrpp6MRmC38iss9dsl57QOHa/fkyTxFWm9Mi+1BSCsBWsDR6CeHwmXX/GLOf5eM5NNp210nkLqRBnY5DTETXn6yERf+oAeRBDn0teVD//Vs0N0OZKzKZzaIeesiPQg0JZAOcMMD7AaTJvqC+ZPfGAO+rhXMeRjboBsHGxbxqG2x ml-infra-dev"
}

resource "aws_instance" "test_instance" {
  count = "${local.enable_test_resources}"

  ami                    = "${data.aws_ami.sre_ubuntu.id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${module.default_security_groups.private_ssh_security_group_id}"]

  key_name = "${aws_key_pair.deployer.key_name}"

  # since I don't have a way into the VPC yet... put it in public and get a public IP.
  subnet_id                   = "${element(module.vpc.private_subnets, 0)}"
  associate_public_ip_address = false

  tags = "${merge(local.common_tags, map("Name", "terraform-test-${module.vpc.vpc_id}"))}"
}

##############################################################################
#                                                                            #
#                                 OUTPUTS                                    #
#                                                                            #
##############################################################################

# ***NOTE: Make sure that these are given default values in the
# terraform_remote_state.shared_us_east_1_remote_state defined above.

#
# Setup a few datasources for outputs
#
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${module.vpc.vpc_id}"
}

output "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  value       = "${module.vpc.vpc_cidr_block}"
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = "${module.vpc.public_route_table_ids}"
}

output "public_route_table_ids_count" {
  description = "Count of list of IDs of public route tables"
  value       = "${length(module.vpc.public_route_table_ids)}"
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = "${module.vpc.private_route_table_ids}"
}

output "private_route_table_ids_count" {
  description = "Count of list of IDs of private route tables"
  value       = "${length(module.vpc.private_route_table_ids)}"
}

output "account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}

output "region" {
  value = "${data.aws_region.current.id}"
}

output "Z_Test_DNS_A_Record" {
  value = "dig +short ${aws_route53_record.test_A_record.0.fqdn}"
}

output "Z_Test_SSH_Host" {
  value = "ssh -i ~/.ssh/ml-infra-dev.pem ubuntu@${aws_instance.test_instance.0.private_ip}"
}

output "vpc_flowlog_URL" {
  value = "${module.vpc_flowlog.vpc_flowlog_URL}"
}
