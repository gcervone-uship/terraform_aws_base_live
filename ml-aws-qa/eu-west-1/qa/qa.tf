module "vpc" {
  source = "../../../../terraform_aws_base/vpc"

  #
  # VPC Configuration
  #
  vpc_name = "qa"
  vpc_cidr = "10.18.112.0/20"
  vpc_azs = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_private_subnets = ["10.18.112.0/23", "10.18.114.0/23", "10.18.116.0/23"]
  vpc_public_subnets = ["10.18.120.0/25", "10.18.120.128/25", "10.18.121.0/25"]
  vpc_database_subnets = ["10.18.122.0/25", "10.18.122.128/25", "10.18.123.0/25"]
  vpc_elasticache_subnets = ["10.18.124.0/25", "10.18.124.128/25", "10.18.125.0/25"]
  vpc_redshift_subnets = ["10.18.126.0/25", "10.18.126.128/25", "10.18.127.0/25"]

  common_tags = "${local.common_tags}"
}