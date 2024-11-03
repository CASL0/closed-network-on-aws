output "acm_server_certificate_arn" {
  value       = aws_acm_certificate.server.arn
  description = "サーバー証明書のARN"
}

output "acm_client_certificate_arn" {
  value       = aws_acm_certificate.client.arn
  description = "クライアント証明書のARN"
}

output "vpce_for_s3" {
  value       = module.endpoints.endpoints.s3.id
  description = "S3用のVPC Endpoint"
}
