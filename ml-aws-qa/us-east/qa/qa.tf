module "vpc" {
  source = "../../../../terraform_aws_base/vpc"

  #
  # VPC Configuration
  #
  vpc_name = "qa"
  vpc_cidr = "10.18.96.0/20"
  vpc_azs = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  vpc_private_subnets = ["10.18.96.0/23", "10.18.98.0/23", "10.18.100.0/23", "10.18.102.0/23"]
  vpc_public_subnets = ["10.18.104.0/25", "10.18.104.128/25", "10.18.105.0/25", "10.18.105.128/25"]
  vpc_database_subnets = ["10.18.106.0/25", "10.18.106.128/25", "10.18.107.0/25", "10.18.107.128/25"]
  vpc_elasticache_subnets = ["10.18.108.0/25", "10.18.108.128/25", "10.18.109.0/25", "10.18.109.128/25"]
  vpc_redshift_subnets = ["10.18.110.0/25", "10.18.110.128/25", "10.18.111.0/25", "10.18.111.128/25"]

  common_tags = "${local.common_tags}"
}