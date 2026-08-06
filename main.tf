locals {
  context_subject_prefix = var.context == null ? null : {
    environment = "environment:"
    branch      = "ref:refs/heads/"
    tag         = "ref:refs/tags/"
  }

  contexts = (
    var.context == null
    ? ["*"]
    : var.context.type == "pull_request" ? ["pull_request"]
    : [for v in var.context.values : "${local.context_subject_prefix[var.context.type]}${v}"]
  )

  # GitHub embeds immutable numeric owner and repository IDs in the `sub` claim —
  # `repo:OWNER@OWNER_ID/NAME@REPO_ID` instead of `repo:OWNER/NAME` — for repositories created
  # after 2026-07-15 and for older repositories which opted in. A repository issues one form or
  # the other, never both, so both subjects are trusted while the migration is in progress. Set
  # `var.trust_mutable_subject` to `false` to stop trusting the name-based subject once a
  # repository is known to issue immutable claims.
  #
  # https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/
  repository_owner = split("/", var.github_repository.full_name)[0]
  repository_name  = split("/", var.github_repository.full_name)[1]

  immutable_repository = (
    var.github_owner_id == null || var.github_repository.repo_id == null
    ? null
    : "${local.repository_owner}@${var.github_owner_id}/${local.repository_name}@${var.github_repository.repo_id}"
  )

  repositories = compact([
    var.trust_mutable_subject ? var.github_repository.full_name : null,
    local.immutable_repository,
  ])
}

resource "aws_iam_role" "this" {
  name        = var.iam_role_name_prefix == null ? coalesce(var.iam_role_name, "github-actions-${md5(data.aws_iam_policy_document.this.json)}") : null
  name_prefix = var.iam_role_name_prefix

  assume_role_policy   = data.aws_iam_policy_document.this.json
  max_session_duration = var.max_session_duration

  tags = merge(var.default_tags, var.iam_role_tags)

  lifecycle {
    precondition {
      condition     = length(local.repositories) > 0
      error_message = "With `trust_mutable_subject` set to `false`, both `github_owner_id` and `github_repository.repo_id` must be set — otherwise the IAM role would trust no subject at all."
    }
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    principals {
      type        = "Federated"
      identifiers = [var.iam_openid_connect_provider.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      variable = "token.actions.githubusercontent.com:aud"
      test     = "StringEquals"
      values   = [var.openid_audience]
    }

    condition {
      variable = "token.actions.githubusercontent.com:sub"
      test     = "StringLike"
      values = flatten([
        for repository in local.repositories : [
          for c in local.contexts : "repo:${repository}:${c}"
        ]
      ])
    }
  }
}
