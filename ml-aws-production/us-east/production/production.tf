module "vpc" {
  source = "../../../../terraform_aws_base/vpc"

  #
  # VPC Configuration
  #
  vpc_name = "production"

  vpc_cidr                = "10.18.160.0/20"
  vpc_azs                 = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  vpc_private_subnets     = ["10.18.160.0/23", "10.18.162.0/23", "10.18.164.0/23", "10.18.166.0/23"]
  vpc_public_subnets      = ["10.18.168.0/25", "10.18.168.128/25", "10.18.169.0/25", "10.18.169.128/25"]
  vpc_database_subnets    = ["10.18.170.0/25", "10.18.170.128/25", "10.18.171.0/25", "10.18.171.128/25"]
  vpc_elasticache_subnets = ["10.18.172.0/25", "10.18.172.128/25", "10.18.173.0/25", "10.18.173.128/25"]
  vpc_redshift_subnets    = ["10.18.174.0/25", "10.18.174.128/25", "10.18.175.0/25", "10.18.175.128/25"]

  common_tags = "${local.common_tags}"
}
