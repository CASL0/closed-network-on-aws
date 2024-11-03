module "s3" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${local.name}-bucket"

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
      variable = "aws:SourceVpc"
      values   = [module.vpc.vpc_id]
    }
  }
}

resource "aws_s3_bucket_policy" "vpce_bucket_policy" {
  bucket = module.s3.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_vpce_policy.json
}
