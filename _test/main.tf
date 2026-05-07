terraform {
  required_providers {
    github = {
      source = "integrations/github"
    }
  }
  required_version = ">= 1.3"
}

provider "aws" {
  region = "local"
}

module "iam_role" {
  source = "./.."

  github_repository           = github_repository.example
  iam_openid_connect_provider = aws_iam_openid_connect_provider.github
}

module "iam_role_with_environment_context" {
  source = "./.."

  github_repository           = github_repository.example
  iam_openid_connect_provider = aws_iam_openid_connect_provider.github

  context = {
    type   = "environment"
    values = ["production", "staging"]
  }
}

module "iam_role_with_pull_request_context" {
  source = "./.."

  github_repository           = github_repository.example
  iam_openid_connect_provider = aws_iam_openid_connect_provider.github

  context = {
    type = "pull_request"
  }
}

module "iam_role_with_branch_context" {
  source = "./.."

  github_repository           = github_repository.example
  iam_openid_connect_provider = aws_iam_openid_connect_provider.github

  context = {
    type   = "branch"
    values = ["main", "release/*"]
  }
}

module "iam_role_with_tag_context" {
  source = "./.."

  github_repository           = github_repository.example
  iam_openid_connect_provider = aws_iam_openid_connect_provider.github

  context = {
    type   = "tag"
    values = ["v*"]
  }
}

module "iam_role_with_custom_name" {
  source = "./.."

  github_repository           = github_repository.example
  iam_openid_connect_provider = aws_iam_openid_connect_provider.github

  iam_role_name = "custom-role-name"
}

module "iam_role_with_name_prefix" {
  source = "./.."

  github_repository           = github_repository.example
  iam_openid_connect_provider = aws_iam_openid_connect_provider.github

  iam_role_name_prefix = "github-actions-"
}

module "iam_role_with_all_options" {
  source = "./.."

  github_repository           = github_repository.example
  iam_openid_connect_provider = aws_iam_openid_connect_provider.github

  context = {
    type   = "environment"
    values = ["production"]
  }

  max_session_duration = 7200
  openid_audience      = "sts.amazonaws.com"

  default_tags = {
    Project = "example"
  }

  iam_role_tags = {
    Owner = "team-infra"
  }
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
