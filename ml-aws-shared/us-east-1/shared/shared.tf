locals {
  common_tags = {
    Terraform   = "true"
    division    = "operations"
    project     = "aws base"
    environment = "shared"
    envid       = "unknown"
    role        = "unknown"
  }
}

terraform {
  backend "s3" {
    # https://s3.console.aws.amazon.com/s3/buckets/ml-sre-terraform-aws-base/?region=us-east-1&tab=overview
    bucket = "ml-sre-terraform-aws-base"
    key    = "ml-aws-sandbox/us-east-1/shared/terraform.tfstate"
    region = "us-east-1"

    # uses access_key and secret_key from default aws config
    # role_arn = "arn:aws:iam::652911386828:role/sre"
    profile = "awx_shared"
  }
}

provider "aws" {
  version = "~> 1.10"
  allowed_account_ids = ["652911386828"]
  region              = "us-east-1"
  profile             = "awx_shared"
}

provider "aws" {
  alias = "maindomain-shared"
  version = "~> 1.10"
  allowed_account_ids = ["652911386828"]
  region              = "us-east-1"
  profile             = "awx_shared"
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

  #
  # Subdomain configuration.
  #   1. Create subdomain
  #   2. Add glue recrods to maindomain_name hosted zone
  #   3. Request a DNS validated (automated) SSL cert for *.<subdomain>
  #

  maindomain_name = "mml.cloud."
  subdomain_prefix = "sh" // shared
}


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

