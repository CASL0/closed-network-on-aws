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

data "aws_region" "current" {}

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "${local.name}-webapp"
  repository_type = "private"

  repository_force_delete = true

  repository_read_write_access_arns = concat([data.aws_caller_identity.current.arn], var.additional_repository_read_write_access_arns)
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

data "aws_iam_policy_document" "ecr_pull_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::prod-${data.aws_region.current.name}-starport-layer-bucket/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_vpc_endpoint_policy" "vpce_ecr_policy" {
  vpc_endpoint_id = module.endpoints.endpoints.s3_gateway.id
  policy          = data.aws_iam_policy_document.ecr_pull_policy.json
}

################################################################################
# ECS
################################################################################

locals {
  dkr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${local.name}-cluster"

  fargate_capacity_providers = {
    FARGATE = {
      name = "FARGATE"
    }
  }

  services = {
    webapp = {
      cpu    = 1024
      memory = 2048

      container_definitions = {
        webapp = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "${local.dkr_registry}/${local.name}-webapp:v1"
          port_mappings = [
            {
              name          = "webapp-80"
              containerPort = 80
              protocol      = "tcp"
            }
          ]

          readonly_root_filesystem = true
        }
      }

      service_connect_configuration = {
        enable    = true
        namespace = aws_service_discovery_http_namespace.default.arn
        service = {
          client_alias = {
            port     = 80
            dns_name = "webapp"
          }
          port_name      = "webapp-80"
          discovery_name = "webapp-svc"
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["ecs"].arn
          container_name   = "webapp"
          container_port   = 80
        }
      }

      subnet_ids = slice(module.vpc.intra_subnets, 0, var.az_count)

      security_group_rules = {
        alb_ingress = {
          type                     = "ingress"
          from_port                = 80
          to_port                  = 80
          protocol                 = "tcp"
          description              = "Service port"
          source_security_group_id = module.alb.security_group_id
        }
        egress = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }

  depends_on = [module.ecr]

  tags = local.tags
}

resource "aws_service_discovery_http_namespace" "default" {
  name        = "${local.name}-ns"
  description = "CloudMap namespace for ${local.name}"
  tags        = local.tags
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
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "s3-endpoints"
      }

      rules = {
        s3 = {
          actions = [
            {
              type             = "forward"
              target_group_key = "s3-endpoints"
            }
          ]
          conditions = [{
            host_header = {
              values = ["www.${var.domain_name}"]
            }
          }]
        }
        ecs = {
          actions = [
            {
              type             = "forward"
              target_group_key = "ecs"
            }
          ]
          conditions = [{
            host_header = {
              values = ["app.${var.domain_name}"]
            }
          }]
        }
      }
    }

    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = var.ssl_policy
      certificate_arn = aws_acm_certificate.ssl_server.arn
      forward = {
        target_group_key = "s3-endpoints"
      }

      rules = {
        s3 = {
          actions = [
            {
              type             = "forward"
              target_group_key = "s3-endpoints"
            }
          ]
          conditions = [{
            host_header = {
              values = ["www.${var.domain_name}"]
            }
          }]
        }
        ecs = {
          actions = [
            {
              type             = "forward"
              target_group_key = "ecs"
            }
          ]
          conditions = [{
            host_header = {
              values = ["app.${var.domain_name}"]
            }
          }]
        }
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
    ecs = {
      protocol    = "HTTP"
      target_type = "ip"
      # ecs module側でアタッチする
      create_attachment = false

      health_check = {
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200"
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
    app = {
      name    = "app.${var.domain_name}"
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
