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
    key    = "ACCOUNTNAME/REGION/ENVIRONMENT/terraform.tfstate" # CHANGEME - Must be a unique key name for this env.
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
    environment = "EXAMPLE"    # CHANGEME - Based on published tagging standards.
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
  allowed_account_ids     = ["123456789012"]              # CHANGEME - To ensure credentials (profile) matches expectations
  region                  = "us-east-1"
  shared_credentials_file = "../../../common/credentials"
  profile                 = "PROFILE_NAME"                # CHANGEME - AWS profile to use for creds
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
  vpc_name = "EXAMPLE"

  vpc_cidr                = "10.0.0.0/16"
  vpc_azs                 = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  vpc_private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
  vpc_public_subnets      = ["10.0.5.0/24", "10.0.6.0/24", "10.0.7.0/24", "10.0.8.0/24"]
  vpc_database_subnets    = ["10.0.9.0/24", "10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  vpc_elasticache_subnets = ["10.0.13.0/24", "10.0.14.0/24", "10.0.15.0/24", "10.0.16.0/24"]
  vpc_redshift_subnets    = ["10.0.17.0/24", "10.0.18.0/24", "10.0.19.0/24", "10.0.20.0/24"]

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
  subdomain_prefix               = "example" # example.mml.cloud (example account)
}
