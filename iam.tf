################################################################################
# S3 Policy
################################################################################

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

################################################################################
# VPC Endpoint Policy
################################################################################

data "aws_iam_policy_document" "dkr_image_layer_pull_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::prod-${data.aws_region.current.name}-starport-layer-bucket/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}
