module "vpc" {
  source = "../../../../terraform_aws_base/vpc"

  #
  # VPC Configuration
  #
  vpc_name = "production"
  vpc_cidr = "10.18.176.0/20"
  vpc_azs = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_private_subnets = ["10.18.176.0/23", "10.18.178.0/23", "10.18.180.0/23"]
  vpc_public_subnets = ["10.18.184.0/25", "10.18.184.128/25", "10.18.185.0/25"]
  vpc_database_subnets = ["10.18.186.0/25", "10.18.186.128/25", "10.18.187.0/25"]
  vpc_elasticache_subnets = ["10.18.188.0/25", "10.18.188.128/25", "10.18.189.0/25"]
  vpc_redshift_subnets = ["10.18.190.0/25", "10.18.190.128/25", "10.18.191.0/25"]

  common_tags = "${local.common_tags}"
}