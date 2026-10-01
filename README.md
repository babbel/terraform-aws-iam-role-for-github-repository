# AWS IAM Role Assumable via OpenID by GitHub Actions Workflows

Terraform module creating an IAM role which can be assumed via OpenID by a GitHub-repository-specific GitHub Actions workflow.

https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

## Usage

```tf
module "iam_role" {
  source  = "babbel/iam-role-for-github-repository/aws"
  version = "~> 4.0"

  github_repository           = github_repository.example
  github_owner_id             = data.github_organization.example.id
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

GitHub issues OIDC tokens whose `sub` claim identifies the repository either by immutable numeric
IDs (`repo:OWNER@OWNER_ID/NAME@REPO_ID`) or by name (`repo:OWNER/NAME`). The immutable format is the
default for repositories created after 2026-07-15 and is opt-in for older ones.

This module only ever trusts the immutable subject claim, which is why `github_owner_id` is part of
the usage above and why `github_repository` must carry `repo_id`. A repository must have opted in to
the immutable claim (or have been created after 2026-07-15) before its IAM role can be created or
updated with this module — see
[`gh api repos/OWNER/NAME/actions/oidc/customization/sub --jq .sub_claim_prefix`](https://docs.github.com/en/rest/actions/oidc)
to check, and the REST API to opt a repository in, since the GitHub Terraform provider has no
resource for it.

Trusting the legacy name-based claim (`trust_mutable_subject`) was removed in v5.0.0 — see the
[v5.0.0 release notes](https://github.com/babbel/terraform-aws-iam-role-for-github-repository/releases/tag/v5.0.0)
if you're migrating a role still using it.

https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/
