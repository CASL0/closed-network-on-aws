locals {
  name     = "closed-network-on-aws"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)
  vpc_cidr = "10.0.0.0/24"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
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
  intra_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]

  tags = local.tags
}
