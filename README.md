# AWS IAM Role Assumable via OpenID by GitHub Actions Workflows

Terraform module creating an IAM role which can be assumed via OpenID by a GitHub-repository-specific GitHub Actions workflow.

https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

## Usage

```tf
module "iam_role" {
  source  = "babbel/iam-role-for-github-repository/aws"
  version = "~> 3.0"

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

## Subject claim formats

GitHub issues OIDC tokens whose `sub` claim identifies the repository either by name
(`repo:OWNER/NAME`) or by immutable numeric IDs (`repo:OWNER@OWNER_ID/NAME@REPO_ID`). The immutable
format is the default for repositories created after 2026-07-15 and is opt-in for older ones, so
the trust policy has to match the format the repository actually issues.

Pass `github_owner_id` to trust the immutable subject claim in addition to the name-based one:

```tf
module "iam_role" {
  source  = "babbel/iam-role-for-github-repository/aws"
  version = "~> 3.1"

  github_repository           = github_repository.example
  github_owner_id             = data.github_organization.example.id
  iam_openid_connect_provider = aws_iam_openid_connect_provider.github
}
```

Both subjects are trusted so that the same configuration works before and after a repository
migrates. Once a repository issues immutable claims, set `trust_mutable_subject = false` to drop
the name-based subject.

https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/
