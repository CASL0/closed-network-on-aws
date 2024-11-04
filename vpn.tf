################################################################################
# クライアントVPNエンドポイントの作成
################################################################################

resource "aws_ec2_client_vpn_endpoint" "default" {
  description = "VPNエンドポイント"

  server_certificate_arn = aws_acm_certificate.server.arn
  client_cidr_block      = "10.0.4.0/22"

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.client.arn
  }

  connection_log_options {
    enabled = false
  }

  split_tunnel          = true
  vpc_id                = module.vpc.vpc_id
  vpn_port              = 443
  session_timeout_hours = 24

  security_group_ids = [module.security_group.security_group_id]

  tags = local.tags
}

################################################################################
# セキュリティグループ
################################################################################

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "security group for vpn endpoint"
  description = "Security group that allows traffic to and from vpc"

  vpc_id = module.vpc.vpc_id

  ingress_rules       = ["all-icmp", "http-80-tcp", "https-443-tcp", "dns-tcp", "dns-udp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = [local.vpc_cidr]

  tags = local.tags
}

################################################################################
# ターゲットネットワークへのクライアント VPN の関連付け
################################################################################

resource "aws_ec2_client_vpn_network_association" "vpn_to_subnet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.default.id
  subnet_id              = module.vpc.intra_subnets[2]
}

################################################################################
# 承認ルールの追加
################################################################################

resource "aws_ec2_client_vpn_authorization_rule" "allow_all_users" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.default.id
  target_network_cidr    = local.vpc_cidr
  authorize_all_groups   = true
}
