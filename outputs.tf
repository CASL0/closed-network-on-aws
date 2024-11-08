output "acm_server_certificate_arn" {
  value       = aws_acm_certificate.vpn_server.arn
  description = "VPNサーバー証明書のARN"
}

output "acm_client_certificate_arn" {
  value       = aws_acm_certificate.vpn_client.arn
  description = "VPNクライアント証明書のARN"
}

output "vpce_for_s3" {
  value       = module.endpoints.endpoints.s3.id
  description = "S3用のVPC Endpoint"
}

output "route53_resolver_endpoint_ip_addresses" {
  value       = module.inbound_resolver_endpoints.route53_resolver_endpoint_ip_addresses
  description = "Route53 Inbound EndpointのIPアドレス"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "ECRのリポジトリURL"
}
