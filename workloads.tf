################################################################################
# S3
################################################################################

module "s3" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "www.${var.domain_name}"

  force_destroy = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags
}

data "aws_iam_policy_document" "s3_vpce_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3.s3_bucket_arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = [module.endpoints.endpoints.s3.id]
    }
  }
}

resource "aws_s3_bucket_policy" "vpce_bucket_policy" {
  bucket = module.s3.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_vpce_policy.json
}

################################################################################
# ECR
################################################################################

data "aws_caller_identity" "current" {}

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "${local.name}-ecr-repository"
  repository_type = "private"

  repository_force_delete = true

  repository_read_write_access_arns = [data.aws_caller_identity.current.arn]
  create_lifecycle_policy           = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = local.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name     = "${local.name}-alb"
  vpc_id   = module.vpc.vpc_id
  internal = true
  subnets  = slice(module.vpc.intra_subnets, 0, var.az_count)

  enable_deletion_protection = false

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = local.vpc_cidr
    }
  }

  listeners = {
    s3-http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "s3-endpoints"
      }
    }
    s3-https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = var.ssl_policy
      certificate_arn = aws_acm_certificate.ssl_server.arn
      forward = {
        target_group_key = "s3-endpoints"
      }
    }
  }

  target_groups = {
    s3-endpoints = {
      name_prefix       = "vpce-"
      protocol          = "HTTP"
      target_type       = "ip"
      create_attachment = false

      health_check = {
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200,307,405"
      }
    }
  }

  additional_target_group_attachments = {
    for k in range(var.az_count) : k => {
      target_group_key = "s3-endpoints"
      target_id        = tolist(module.endpoints.endpoints.s3.subnet_configuration)[k].ipv4
      port             = 80
    }
  }

  route53_records = {
    www = {
      name    = "www.${var.domain_name}"
      type    = "A"
      zone_id = aws_route53_zone.private_hosted_zone.zone_id
    }
  }

  tags = local.tags
}

resource "aws_route53_zone" "private_hosted_zone" {
  name = var.domain_name

  force_destroy = true

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  tags = local.tags
}
