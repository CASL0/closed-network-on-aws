# closed-network-on-aws

閉域網からアクセス可能な AWS 上の Web アプリケーションを構築します。

## 構成

![infra](https://raw.githubusercontent.com/CASL0/closed-network-on-aws/refs/heads/images/infra.svg)

## Prerequisites

### Terraform

以下を参考に Terraform をインストールしてください。

- https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

### AWS CLI

以下を参考に AWS CLI をインストールしてください。

- https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html

### OpenVPN easy-rsa

以下を参考に easy-rsa のインストール、サーバーとクライアントの証明書・秘密鍵の生成をしてください。

- https://catalog.us-east-1.prod.workshops.aws/workshops/be2b90c2-06a1-4ae6-84b3-c705049d2b6f/ja-JP/03-hands-on/03-01-common/04-certificate

## Usage

1. 上記で生成したサーバーとクライアントの証明書・秘密鍵を以下のパスに配置してください。
   - `files/vpn/ca.crt`：ルート証明書
   - `files/vpn/server.crt`：サーバー証明書
   - `files/vpn/server.key`：サーバー秘密鍵
   - `files/vpn/client.crt`：クライアント証明書
   - `files/vpn/client.key`：クライアント秘密鍵
1. 以下のコマンドを実行してください。

```bash
terraform init
terraform apply
```

## 構築した環境に接続

### AWS Client VPN のインストール

以下のサイトから VPN クライアントソフトをインストールしてください。

- https://aws.amazon.com/jp/vpn/client-vpn-download/

### VPN プロファイルの設定

1.  AWS マネジメントコンソールにてクライアント VPN エンドポイントの設定にアクセスします。
1.  [クライアント設定ファイルをダウンロード]をクリックし、`downloaded-client-config.ovpn`をダウンロードします。
1.  `downloaded-client-config.ovpn`を編集し、クライアント証明書の情報を末尾に追加してください。

    ```
    <cert>
    -----BEGIN CERTIFICATE-----
    ~ クライアント証明書 ~
    -----END CERTIFICATE-----
    </cert>

    <key>
    -----BEGIN PRIVATE KEY-----
    ~ クライアント秘密鍵 ~
    -----END PRIVATE KEY-----
    </key>
    ```

1.  上記で編集して`downloaded-client-config.ovpn`を VPN クライアントで読み込みプロファイルを追加してください。
1.  DNS を Route53 にフォワードするために、接続する PC の DNS 設定を[インバウンドエンドポイント](https://ap-northeast-1.console.aws.amazon.com/route53resolver/home?region=ap-northeast-1#/inbound-endpoints)の IP アドレスに修正してください。

<!-- prettier-ignore-start -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.00 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.74.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | ~> 9.0 |
| <a name="module_endpoints"></a> [endpoints](#module\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | n/a |
| <a name="module_inbound_resolver_endpoints"></a> [inbound\_resolver\_endpoints](#module\_inbound\_resolver\_endpoints) | terraform-aws-modules/route53/aws//modules/resolver-endpoints | n/a |
| <a name="module_s3"></a> [s3](#module\_s3) | terraform-aws-modules/s3-bucket/aws | n/a |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | terraform-aws-modules/security-group/aws | ~> 5.0 |
| <a name="module_security_group_inbound_resolver_endpoints"></a> [security\_group\_inbound\_resolver\_endpoints](#module\_security\_group\_inbound\_resolver\_endpoints) | terraform-aws-modules/security-group/aws | ~> 5.0 |
| <a name="module_security_group_vpc_endpoints"></a> [security\_group\_vpc\_endpoints](#module\_security\_group\_vpc\_endpoints) | terraform-aws-modules/security-group/aws | ~> 5.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.ssl_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate.vpn_client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate.vpn_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_ec2_client_vpn_authorization_rule.allow_all_users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_authorization_rule) | resource |
| [aws_ec2_client_vpn_endpoint.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_endpoint) | resource |
| [aws_ec2_client_vpn_network_association.vpn_to_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_network_association) | resource |
| [aws_route53_zone.private_hosted_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_s3_bucket_policy.vpce_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_iam_policy_document.s3_vpce_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | AZ数 | `number` | `2` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | ドメイン名 | `string` | `"casl0.github.io"` | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | TLS セキュリティポリシー | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acm_client_certificate_arn"></a> [acm\_client\_certificate\_arn](#output\_acm\_client\_certificate\_arn) | VPNクライアント証明書のARN |
| <a name="output_acm_server_certificate_arn"></a> [acm\_server\_certificate\_arn](#output\_acm\_server\_certificate\_arn) | VPNサーバー証明書のARN |
| <a name="output_route53_resolver_endpoint_ip_addresses"></a> [route53\_resolver\_endpoint\_ip\_addresses](#output\_route53\_resolver\_endpoint\_ip\_addresses) | Route53 Inbound EndpointのIPアドレス |
| <a name="output_vpce_for_s3"></a> [vpce\_for\_s3](#output\_vpce\_for\_s3) | S3用のVPC Endpoint |
<!-- END_TF_DOCS -->
<!-- prettier-ignore-end -->
