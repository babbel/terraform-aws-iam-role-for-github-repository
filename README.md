# AWS IAM Role Assumable via OpenID by GitHub Actions Workflows

Terraform module creating an IAM role which can be assumed via OpenID by a GitHub-repository-specific GitHub Actions workflow.

https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

## Usage

```tf
module "iam_role" {
  source  = "babbel/iam-role-for-github-repository/aws"
  version = "~> 2.0"

  github_repository           = github_repository.example
  iam_openid_connect_provider = aws_iam_openid_connect_provider.github
}

resource "github_repository" "example" {
  name = "example"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = data.tls_certificate.github.url

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [local.github-certificate.sha1_fingerprint]
}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  github-certificate = one([
    for certificate in data.tls_certificate.github.certificates :
    certificate
    if !certificate.is_ca
  ])
}
```
