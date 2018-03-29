module "vpc" {
  source = "../../../../terraform_aws_base/vpc"

  #
  # VPC Configuration
  #
  vpc_name = "development"
  vpc_cidr = "10.18.80.0/20"
  vpc_azs = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_private_subnets = ["10.18.80.0/23", "10.18.82.0/23", "10.18.84.0/23"]
  vpc_public_subnets = ["10.18.88.0/25", "10.18.88.128/25", "10.18.89.0/25"]
  vpc_database_subnets = ["10.18.90.0/25", "10.18.90.128/25", "10.18.91.0/25"]
  vpc_elasticache_subnets = ["10.18.92.0/25", "10.18.92.128/25", "10.18.93.0/25"]
  vpc_redshift_subnets = ["10.18.94.0/25", "10.18.94.128/25", "10.18.95.0/25"]

  common_tags = "${local.common_tags}"
}