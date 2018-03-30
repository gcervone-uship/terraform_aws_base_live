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
  source = "../../../../terraform_aws_base/vpc_peering"

  enable_vpc_peering = "${local.enable_vpc_peering}"

  providers = {
    "aws.peer" = "aws.shared-us-west-1" # defined in global.tf  todo change this to east when have the limits raised.
    "aws"      = "aws"                  # defined locally
  }

  my_vpcid          = "${module.vpc.vpc_id}"
  peer_vpcid        = "${data.terraform_remote_state.shared_us_east_1_remote_state.vpc_id}"
  peer_vpc_owner_id = "${data.terraform_remote_state.shared_us_east_1_remote_state.account_id}"
  peer_vpc_region   = "${data.terraform_remote_state.shared_us_east_1_remote_state.region}"

  common_tags = "${local.common_tags}"
}

#
# Add the default security groups to the VPC created above
#
module "default_security_groups" {

  enable_default_security_groups = "${local.enable_default_security_groups}"
  source = "../../../../terraform_aws_base/default_security_groups"

  vpc_id = "${module.vpc.vpc_id}"

  common_tags = "${local.common_tags}"
}

module "subdomain" {
  source = "../../../../terraform_aws_base/subdomain"

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
  name    = "test"
  type    = "A"
  zone_id = "${module.subdomain.zone_id}"
  ttl     = "30"

  records = ["127.0.0.1"]
}

