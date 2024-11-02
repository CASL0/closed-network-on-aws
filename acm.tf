locals {
  ca_certificate = file("${path.module}/files/vpn/ca.crt")

  server_certificate = file("${path.module}/files/vpn/server.crt")
  server_key         = file("${path.module}/files/vpn/server.key")

  client_certificate = file("${path.module}/files/vpn/client.crt")
  client_key         = file("${path.module}/files/vpn/client.key")
}

resource "aws_acm_certificate" "server" {
  certificate_body  = local.server_certificate
  private_key       = local.server_key
  certificate_chain = local.ca_certificate

  tags = local.tags
}

resource "aws_acm_certificate" "client" {
  certificate_body  = local.client_certificate
  private_key       = local.client_key
  certificate_chain = local.ca_certificate

  tags = local.tags
}
