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
    bucket         = "ml-sre-terraform-aws-base"
    key            = "ml-aws-qa/us-east-1/qa/terraform.tfstate" # Key should be the only change needed.
    dynamodb_table = "ml-sre-terraform-aws-base"
    region         = "us-east-1"

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
    environment = "qa"
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
  allowed_account_ids     = ["000000000000"]              # <<<---- todo change to real account ID when we it created.
  region                  = "us-east-1"
  shared_credentials_file = "../../../common/credentials"
  profile                 = "terraform_qa"
}

##############################################################################
#                                                                            #
#                                VPC SETUP                                   #
#                                                                            #
##############################################################################

#
# Creates and configures the vpc, subnets, subnet groups, internet gateways and NAT gateways
#
locals {
  vpc_name = "qa"

  vpc_cidr                = "10.18.96.0/20"
  vpc_azs                 = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  vpc_private_subnets     = ["10.18.96.0/23", "10.18.98.0/23", "10.18.100.0/23", "10.18.102.0/23"]
  vpc_public_subnets      = ["10.18.104.0/25", "10.18.104.128/25", "10.18.105.0/25", "10.18.105.128/25"]
  vpc_database_subnets    = ["10.18.106.0/25", "10.18.106.128/25", "10.18.107.0/25", "10.18.107.128/25"]
  vpc_elasticache_subnets = ["10.18.108.0/25", "10.18.108.128/25", "10.18.109.0/25", "10.18.109.128/25"]
  vpc_redshift_subnets    = ["10.18.110.0/25", "10.18.110.128/25", "10.18.111.0/25", "10.18.111.128/25"]

  enable_vpc_peering                     = true
  enable_vpc_peering_route_table_updates = true
  enable_default_security_groups         = true
  enable_vpc_flow_logs                   = true
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
  enable_subdomain               = true
  enable_subdomain_wildcard_cert = true
  subdomain_prefix               = "qa" # qa.mml.cloud (qa account)
}
