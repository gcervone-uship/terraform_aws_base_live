locals {

  # Common tags for passing down to various modules.  These will be used as a default set of tags to use in
  # downstream resources.
  common_tags = {
    Terraform   = "true"
    division    = "operations"
    project     = "aws base"
    environment = "proto"
    envid       = "unknown"
    role        = "unknown"
  }
}

#
# Terraform backend that holds the state files.  Each environment should have it's own state file.
# https://s3.console.aws.amazon.com/s3/buckets/ml-sre-terraform-aws-base/?region=us-east-1&tab=overview
terraform {
  backend "s3" {
    bucket = "ml-sre-terraform-aws-base"
    key    = "ml-aws-prototype/us-east-1/prototype/terraform.tfstate"
    region = "us-east-1"

    shared_credentials_file = "../../../credentials"
    profile = "terraform_shared"
  }
}

provider "aws" {
  version = "~> 1.10"
  allowed_account_ids = ["758748077998"]
  region              = "us-east-1"
  shared_credentials_file = "../../../credentials"
  profile             = "terraform_prototype"
}

provider "aws" {
  alias = "maindomain-shared"
  version = "~> 1.10"
  allowed_account_ids = ["652911386828"]
  region              = "us-west-1"
  shared_credentials_file = "../../../credentials"
  profile             = "terraform_shared"
}

//module "default_security_groups" {
//  source = "../../../../terraform_aws_base/default_security_groups"
//
//  common_tags = "${local.common_tags}"
//}

module "subdomain" {
  source = "../../../../terraform_aws_base/subdomain"

  providers = {
    "aws.maindomain" = "aws.maindomain-shared"
    "aws" = "aws"
  }
  maindomain_name = "mml.cloud."
  subdomain_prefix = "pt" // prototype
}

module "vpc" {
  source = "../../../../terraform_aws_base/vpc"

  #
  # VPC Configuration
  #
  vpc_name = "prototype"
  vpc_cidr = "10.18.224.0/24"
  vpc_azs = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  vpc_private_subnets = ["10.18.224.0/28", "10.18.224.16/28", "10.18.224.32/28", "10.18.224.48/28"]
  vpc_public_subnets = ["10.18.224.64/28", "10.18.224.80/28", "10.18.224.96/28"]
  vpc_database_subnets = ["10.18.224.112/28", "10.18.224.128/28", "10.18.224.144/28"]
  vpc_elasticache_subnets = ["10.18.224.160/28", "10.18.224.176/28", "10.18.224.192/28"]
  vpc_redshift_subnets = ["10.18.224.208/28", "10.18.224.224/28", "10.18.224.240/28"]

  common_tags = "${local.common_tags}"

}

data "terraform_remote_state" "vpc_peer" {

  backend = "s3"
  config {
    # https://s3.console.aws.amazon.com/s3/buckets/ml-sre-terraform-aws-base/?region=us-east-1&tab=overview
    bucket = "ml-sre-terraform-aws-base"
    key    = "ml-aws-shared/us-east-1/shared/terraform.tfstate"
    region = "us-east-1"
    shared_credentials_file = "../../../credentials"
    profile = "terraform_shared"
  }

}


module "vpc_peer" {
  source = "../../../../terraform_aws_base/vpc_peering"

  providers = {
    "aws.peer" = "aws.maindomain-shared"
    "aws" = "aws"
  }

  my_vpcid = "${module.vpc.vpc_id}"
  peer_vpcid = "${data.terraform_remote_state.vpc_peer.vpc_id}"
  peer_vpc_owner_id = "${data.terraform_remote_state.vpc_peer.account_id}"
  peer_vpc_region = "${data.terraform_remote_state.vpc_peer.region}"

  common_tags = "${local.common_tags}"
}