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

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name     = "${local.name}-alb"
  vpc_id   = module.vpc.vpc_id
  internal = true
  subnets  = slice(module.vpc.intra_subnets, 0, 2)

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
  }

  target_groups = {
    s3-endpoints = {
      name_prefix = "vpce-"
      protocol    = "HTTP"
      port        = 80
      target_type = "ip"
      target_id   = tolist(module.endpoints.endpoints.s3.subnet_configuration)[0].ipv4

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

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.private_hosted_zone.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}
