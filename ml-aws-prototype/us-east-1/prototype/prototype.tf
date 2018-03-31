##############################################################################
#                                                                            #
#                                GENERAL SETUP                               #
#                                                                            #
##############################################################################

#
# Terraform backend that holds the state files.  Each environment should have it's own unique state file.
# See README.md for more info.
# https://s3.console.aws.amazon.com/s3/buckets/ml-sre-terraform-aws-base/?region=us-east-1&tab=overview
#
terraform {
  backend "s3" {
    # https://s3.console.aws.amazon.com/s3/buckets/ml-sre-terraform-aws-base/?region=us-east-1&tab=overview
    bucket = "ml-sre-terraform-aws-base"
    key    = "ml-aws-prototype/us-east-1/prototype/terraform.tfstate"    # Key should be the only change needed.
    region = "us-east-1"

    shared_credentials_file = "../../../common/credentials"
    profile                 = "terraform_shared"
  }
}

locals {
  #
  # Common tags for passing down to various modules.  These will be used as a default set of tags to use in
  # downstream resources.
  #
  common_tags = {
    Terraform   = "true"
    division    = "operations"
    project     = "aws base"
    environment = "proto"
    envid       = "unknown"
    role        = "unknown"
  }

  #
  # Set to true in order to create resources useful in testing, such as test.<subdomain> A record.
  #
  enable_test_resources = true
}

#
# Default provider inherited by all resources that aren't passed a provider explicitly.
#
provider "aws" {
  version                 = "~> 1.10"
  allowed_account_ids     = ["758748077998"]
  region                  = "us-east-1"
  shared_credentials_file = "../../../common/credentials"
  profile                 = "terraform_prototype"
}


##############################################################################
#                                                                            #
#                                VPC SETUP                                   #
#                                                                            #
##############################################################################

#
# Creates and configures the vpc, subnets, subnet groups, internet gateways and NAT gateways
#
module "vpc" {
  source = "git::https://bitbucket.org/mnv_tech/terraform_aws_base.git//vpc?ref=lee/working" # todo change branch.

  vpc_name = "prototype"
  vpc_cidr                = "10.18.224.0/24"
  vpc_azs                 = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  vpc_private_subnets     = ["10.18.224.0/28", "10.18.224.16/28", "10.18.224.32/28", "10.18.224.48/28"]
  vpc_public_subnets      = ["10.18.224.64/28", "10.18.224.80/28", "10.18.224.96/28"]
  vpc_database_subnets    = ["10.18.224.112/28", "10.18.224.128/28", "10.18.224.144/28"]
  vpc_elasticache_subnets = ["10.18.224.160/28", "10.18.224.176/28", "10.18.224.192/28"]
  vpc_redshift_subnets    = ["10.18.224.208/28", "10.18.224.224/28", "10.18.224.240/28"]

  common_tags = "${local.common_tags}"
}

locals {
  enable_vpc_peering = true
  enable_default_security_groups = true
}

##############################################################################
#                                                                            #
#                             ROUTE 53 SUBDOMAIN SETUP                       #
#                                                                            #
##############################################################################

#
# subdomain will create the subdomain hosted zone this this account, and add the
# NS glue records to the maindomain and create a wildcard SSL cert for the subdomain.
#

locals {
  enable_subdomain = true
  subdomain_prefix = "pt"      # pt.mml.cloud (prototype account)
}