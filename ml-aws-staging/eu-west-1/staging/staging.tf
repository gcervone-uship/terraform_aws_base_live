module "vpc" {
  source = "../../../../terraform_aws_base/vpc"

  #
  # VPC Configuration
  #
  vpc_name = "staging"
  vpc_cidr = "10.18.144.0/20"
  vpc_azs = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_private_subnets = ["10.18.144.0/23", "10.18.146.0/23", "10.18.148.0/23"]
  vpc_public_subnets = ["10.18.152.0/25", "10.18.152.128/25", "10.18.153.0/25"]
  vpc_database_subnets = ["10.18.154.0/25", "10.18.154.128/25", "10.18.155.0/25"]
  vpc_elasticache_subnets = ["10.18.156.0/25", "10.18.156.128/25", "10.18.157.0/25"]
  vpc_redshift_subnets = ["10.18.158.0/25", "10.18.158.128/25", "10.18.159.0/25"]

  common_tags = "${local.common_tags}"
}