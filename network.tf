locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-vpc"
  cidr = local.vpc_cidr

  azs = local.azs
  # 各AZに1サブネット+VPNエンドポイント用のサブネット
  intra_subnets = [for k in range(var.az_count + 1) : cidrsubnet(local.vpc_cidr, 3, k)]

  tags = local.tags
}

module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.security_group_vpc_endpoints.security_group_id]
  subnet_ids         = slice(module.vpc.intra_subnets, 0, var.az_count)

  endpoints = {
    s3 = {
      service = "s3"
      tags    = local.tags
    },
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      tags                = local.tags
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      tags                = local.tags
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

################################################################################
# Route53 インバウンドエンドポイント
################################################################################

module "inbound_resolver_endpoints" {
  source = "terraform-aws-modules/route53/aws//modules/resolver-endpoints"

  name      = "${local.name}-resolver"
  direction = "INBOUND"
  protocols = ["Do53", "DoH"]

  subnet_ids = slice(module.vpc.intra_subnets, 0, var.az_count)

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.security_group_inbound_resolver_endpoints.security_group_id]

  create_security_group = false

  tags = local.tags
}

module "security_group_inbound_resolver_endpoints" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "security group for inbound resolver endpoint"
  description = "Security group that allows traffic to inbound resolver endpoint"

  vpc_id = module.vpc.vpc_id

  ingress_rules       = ["dns-tcp", "dns-udp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = local.tags
}
