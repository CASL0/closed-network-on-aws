locals {
  ca_certificate = file("${path.module}/files/ca.crt")

  server_certificate_for_vpn = file("${path.module}/files/vpn/server.crt")
  server_key_for_vpn         = file("${path.module}/files/vpn/server.key")

  client_certificate_for_vpn = file("${path.module}/files/vpn/client.crt")
  client_key_for_vpn         = file("${path.module}/files/vpn/client.key")

  server_certificate_for_ssl = file("${path.module}/files/ssl/server.crt")
  server_key_for_ssl         = file("${path.module}/files/ssl/server.key")
}

resource "aws_acm_certificate" "vpn_server" {
  certificate_body  = local.server_certificate_for_vpn
  private_key       = local.server_key_for_vpn
  certificate_chain = local.ca_certificate

  tags = local.tags
}

resource "aws_acm_certificate" "vpn_client" {
  certificate_body  = local.client_certificate_for_vpn
  private_key       = local.client_key_for_vpn
  certificate_chain = local.ca_certificate

  tags = local.tags
}

resource "aws_acm_certificate" "ssl_server" {
  certificate_body  = local.server_certificate_for_ssl
  private_key       = local.server_key_for_ssl
  certificate_chain = local.ca_certificate

  tags = local.tags
}
