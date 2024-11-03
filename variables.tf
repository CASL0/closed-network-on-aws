locals {
  name     = "closed-network-on-aws"
  vpc_cidr = "10.0.0.0/24"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
