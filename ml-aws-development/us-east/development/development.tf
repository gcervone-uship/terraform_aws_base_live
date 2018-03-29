module "vpc" {
  source = "../../../../terraform_aws_base/vpc"

  #
  # VPC Configuration
  #
  vpc_name = "development"
  vpc_cidr = "10.18.64.0/20"
  vpc_azs = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  vpc_private_subnets = ["10.18.64.0/23", "10.18.66.0/23", "10.18.68.0/23", "10.18.70.0/23"]
  vpc_public_subnets = ["10.18.72.0/25", "10.18.72.128/25", "10.18.73.0/25", "10.18.73.128/25"]
  vpc_database_subnets = ["10.18.74.0/25", "10.18.74.128/25", "10.18.75.0/25", "10.18.75.128/25"]
  vpc_elasticache_subnets = ["10.18.76.0/25", "10.18.76.128/25", "10.18.77.0/25", "10.18.77.128/25"]
  vpc_redshift_subnets = ["10.18.78.0/25", "10.18.78.128/25", "10.18.79.0/25", "10.18.79.128/25"]

  common_tags = "${local.common_tags}"
}