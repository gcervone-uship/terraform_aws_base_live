module "vpc" {
  source = "../../../../terraform_aws_base/vpc"

  #
  # VPC Configuration
  #
  vpc_name = "staging"

  vpc_cidr                = "10.18.128.0/20"
  vpc_azs                 = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  vpc_private_subnets     = ["10.18.128.0/23", "10.18.130.0/23", "10.18.132.0/23", "10.18.134.0/23"]
  vpc_public_subnets      = ["10.18.136.0/25", "10.18.136.128/25", "10.18.137.0/25", "10.18.137.128/25"]
  vpc_database_subnets    = ["10.18.138.0/25", "10.18.138.128/25", "10.18.139.0/25", "10.18.139.128/25"]
  vpc_elasticache_subnets = ["10.18.140.0/25", "10.18.140.128/25", "10.18.141.0/25", "10.18.141.128/25"]
  vpc_redshift_subnets    = ["10.18.142.0/25", "10.18.142.128/25", "10.18.143.0/25", "10.18.143.128/25"]

  common_tags = "${local.common_tags}"
}
