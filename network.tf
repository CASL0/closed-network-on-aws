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
