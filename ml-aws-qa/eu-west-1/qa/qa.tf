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
    key            = "ml-aws-qa/eu-west-1/qa/terraform.tfstate" # Key should be the only change needed.
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
  region                  = "eu-west-1"
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

  vpc_cidr                = "10.18.112.0/20"
  vpc_azs                 = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_private_subnets     = ["10.18.112.0/23", "10.18.114.0/23", "10.18.116.0/23"]
  vpc_public_subnets      = ["10.18.120.0/25", "10.18.120.128/25", "10.18.121.0/25"]
  vpc_database_subnets    = ["10.18.122.0/25", "10.18.122.128/25", "10.18.123.0/25"]
  vpc_elasticache_subnets = ["10.18.124.0/25", "10.18.124.128/25", "10.18.125.0/25"]
  vpc_redshift_subnets    = ["10.18.126.0/25", "10.18.126.128/25", "10.18.127.0/25"]

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
  enable_subdomain               = false # FALSE - Already setup in the us-east-1 config.
  enable_subdomain_wildcard_cert = false # FALSE - Already setup in the us-east-1 config
  subdomain_prefix               = "qa"  # qa.mml.cloud (qa account)
}
