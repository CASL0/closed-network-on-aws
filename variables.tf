locals {
  name     = "closed-network-on-aws"
  vpc_cidr = "10.0.0.0/24"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

variable "domain_name" {
  type        = string
  description = "ドメイン名"
  default     = "casl0.github.io"
}
