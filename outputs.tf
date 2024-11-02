output "acm_server_certificate_arn" {
  value       = aws_acm_certificate.server.arn
  description = "サーバー証明書のARN"
}

output "acm_client_certificate_arn" {
  value       = aws_acm_certificate.client.arn
  description = "クライアント証明書のARN"
}
