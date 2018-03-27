terraform {
  backend "s3" {
    bucket = "ml-sre-terraform-state"
    key    = "ml-aws-prototype/us-east-1/pt/terraform.tfstate"
    region = "us-east-1"

    # uses access_key and secret_key from default aws config
    role_arn = "arn:aws:iam::758748077998:role/sre"
  }
}

module "prototype" {
  source = "../../../../terraform_aws_base"

  #
  # Auth for AWS provider
  #
  admin_role_arn = "arn:aws:iam::758748077998:role/sre"
  region = "us-east-1"


  #
  # Common tags used by resources created by this module.
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
  # Commit map used by the pipeline to insert infra and code commit hashes.
  #
  commit_map = {
    infrastructure_hash = "unknown"
    configuration_hash  = "unknown"
  }

  #
  # Main domain configuration.  Required when enable_subdomain is true.
  # This will be used as a data source for subdomain operations and a target
  # for adding subdomain glue records.
  #
  maindomain_name = "tf.mml.cloud."

  #
  # Subdomain configuration.  Setting enable_subdomain to true will:
  #   1. Create subdomain
  #   2. Add glue recrods to maindomain_name hosted zone
  #   3. Request a DNS validated (automated) SSL cert for *.<subdomain
  #
  enable_subdomain = true
  subdomain_prefix = "pt" // prototype

  #
  # VPC Configuration
  #

  vpc_name = "prototype-vpc"
  vpc_cidr = "10.18.224.0/24"
  vpc_azs = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  vpc_private_subnets = ["10.18.224.0/28", "10.18.224.16/28", "10.18.224.32/28", "10.18.224.48/28"]
  vpc_public_subnets = ["10.18.224.64/28", "10.18.224.80/28", "10.18.224.96/28"]
  vpc_database_subnets = ["10.18.224.112/28", "10.18.224.128/28", "10.18.224.144/28"]
  vpc_elasticache_subnets = ["10.18.224.160/28", "10.18.224.176/28", "10.18.224.192/28"]
  vpc_redshift_subnets = ["10.18.224.208/28", "10.18.224.224/28", "10.18.224.240/28"]

}