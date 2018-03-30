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
    key    = "ml-aws-shared/us-east-1/shared/terraform.tfstate"
    region = "us-east-1"
    shared_credentials_file = "../../../common/credentials"
    profile = "terraform_shared"
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
    environment = "shared"
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
  version = "~> 1.10"
  allowed_account_ids = ["652911386828"]
  region              = "us-west-1"
  shared_credentials_file = "../../../common/credentials"
  profile = "terraform_shared"
}


##############################################################################
#                                                                            #
#                                VPC SETUP                                   #
#                                                                            #
##############################################################################

#
# Creates and configures the vpc, subnets, subnet groups, internet gateways and NAT gateways
#
//module "vpc" {
//  source = "../../../../terraform_aws_base/vpc"
//
//  #
//  # VPC Configuration
//  #
//  vpc_name = "shared"
//  vpc_cidr = "10.18.48.0/20"
//  vpc_azs = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
//  vpc_private_subnets = ["10.18.48.0/23", "10.18.50.0/23", "10.18.52.0/23", "10.18.54.0/23"]
//  vpc_public_subnets = ["10.18.56.0/25", "10.18.56.128/25", "10.18.57.0/25", "10.18.57.128/25"]
//  vpc_database_subnets = ["10.18.58.0/25", "10.18.58.128/25", "10.18.59.0/25", "10.18.59.128/25"]
//  vpc_elasticache_subnets = ["10.18.60.0/25", "10.18.60.128/25", "10.18.61.0/25", "10.18.61.128/25"]
//  vpc_redshift_subnets = ["10.18.62.0/25", "10.18.62.128/25", "10.18.63.0/25", "10.18.63.128/25"]
//
//  common_tags = "${local.common_tags}"
//}

###########################################################################################
######### =====> THIS has been configured for WEST.  The above configuration is for east.
######### =====>  DELETE WHAT"s BELOW AFTER REMOVING ALL RESOURCES.
module "vpc" {
  source = "../../../../terraform_aws_base/vpc"

  #
  # VPC Configuration
  #
  vpc_name = "shared"
  vpc_cidr = "10.18.48.0/20"
  vpc_azs = ["us-west-1a", "us-west-1c"]
  vpc_private_subnets = ["10.18.48.0/23", "10.18.50.0/23", "10.18.52.0/23", "10.18.54.0/23"]
  vpc_public_subnets = ["10.18.56.0/25", "10.18.56.128/25", "10.18.57.0/25", "10.18.57.128/25"]
  vpc_database_subnets = ["10.18.58.0/25", "10.18.58.128/25", "10.18.59.0/25", "10.18.59.128/25"]
  vpc_elasticache_subnets = ["10.18.60.0/25", "10.18.60.128/25", "10.18.61.0/25", "10.18.61.128/25"]
  vpc_redshift_subnets = ["10.18.62.0/25", "10.18.62.128/25", "10.18.63.0/25", "10.18.63.128/25"]

  common_tags = "${local.common_tags}"
}

locals {
  enable_vpc_peering = false
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
  subdomain_prefix = "s"      # sh.mml.cloud (shared account)
}

