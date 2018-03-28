locals {
  common_tags = {
    Terraform   = "true"
    division    = "operations"
    project     = "aws base"
    environment = "proto"
    envid       = "unknown"
    role        = "unknown"
  }
}

terraform {
  backend "s3" {
    # https://s3.console.aws.amazon.com/s3/buckets/ml-sre-terraform-aws-base/?region=us-east-1&tab=overview
    bucket = "ml-sre-terraform-aws-base"
    key    = "ml-aws-sandbox/us-east-1/prototype/terraform.tfstate"
    region = "us-east-1"

    # uses access_key and secret_key from default aws config
    # role_arn = "arn:aws:iam::652911386828:role/sre"
    profile = "awx_shared"
  }
}

provider "aws" {
  version = "~> 1.10"
  allowed_account_ids = ["758748077998"]
  region              = "us-east-1"
  profile             = "sre_prototype"
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
  maindomain_name = "mml.cloud."
  subdomain_prefix = "pt" // prototype
}

//module "vpc" {
//  source = "../../../../terraform_aws_base/vpc"
//
//  #
//  # VPC Configuration
//  #
//  vpc_name = "prototype"
//  vpc_cidr = "10.18.224.0/24"
//  vpc_azs = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
//  vpc_private_subnets = ["10.18.224.0/28", "10.18.224.16/28", "10.18.224.32/28", "10.18.224.48/28"]
//  vpc_public_subnets = ["10.18.224.64/28", "10.18.224.80/28", "10.18.224.96/28"]
//  vpc_database_subnets = ["10.18.224.112/28", "10.18.224.128/28", "10.18.224.144/28"]
//  vpc_elasticache_subnets = ["10.18.224.160/28", "10.18.224.176/28", "10.18.224.192/28"]
//  vpc_redshift_subnets = ["10.18.224.208/28", "10.18.224.224/28", "10.18.224.240/28"]
//
//  common_tags = "${local.common_tags}"
//}