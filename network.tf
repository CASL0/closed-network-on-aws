locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-vpc"
  cidr = local.vpc_cidr

  azs           = local.azs
  intra_subnets = ["10.0.0.0/27", "10.0.0.32/27", "10.0.0.64/27"]

  tags = local.tags
}

module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.security_group_vpc_endpoints.security_group_id]
  subnet_ids         = slice(module.vpc.intra_subnets, 0, 2)

  endpoints = {
    s3 = {
      service = "s3"
      tags    = local.tags
    },
  }

  tags = local.tags
}

module "security_group_vpc_endpoints" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "security group for vpc endpoint"
  description = "Security group that allows traffic to vpc endpoint"

  vpc_id = module.vpc.vpc_id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = [local.vpc_cidr]

  tags = local.tags
}
