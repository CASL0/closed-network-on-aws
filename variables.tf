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

variable "az_count" {
  type        = number
  description = "AZ数"
  default     = 2
}

variable "ssl_policy" {
  type        = string
  description = "TLS セキュリティポリシー"
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}
