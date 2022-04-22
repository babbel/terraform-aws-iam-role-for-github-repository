terraform {
  required_providers {
    github = {
      source  = "integrations/github"
    }
  }
  required_version = ">= 0.13"
}

module "iam_role" {
  source  = "./.."

  github_repository           = github_repository.example
  iam_openid_connect_provider = aws_iam_openid_connect_provider.github
}

resource "github_repository" "example" {
  name = "example"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = data.tls_certificate.github.url

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates.0.sha1_fingerprint]
}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}
