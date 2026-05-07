locals {
  context_raw_values = (
    var.context == null
    ? null
    : var.context.values != null ? var.context.values : (var.context.value != null ? [var.context.value] : null)
  )

  contexts = (
    var.context == null
    ? ["*"]
    : var.context.type == "pull_request" ? ["pull_request"]
    : [
      for v in local.context_raw_values : (
        var.context.type == "environment" ? "environment:${v}" :
        var.context.type == "branch" ? "ref:refs/heads/${v}" :
        var.context.type == "tag" ? "ref:refs/tags/${v}" :
        "invalid_context_type"
      )
    ]
  )
}

resource "aws_iam_role" "this" {
  name        = var.iam_role_name_prefix == null ? coalesce(var.iam_role_name, "github-actions-${md5(data.aws_iam_policy_document.this.json)}") : null
  name_prefix = var.iam_role_name_prefix

  assume_role_policy   = data.aws_iam_policy_document.this.json
  max_session_duration = var.max_session_duration

  tags = merge(var.default_tags, var.iam_role_tags)
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
      values = [
        for c in local.contexts : "repo:${var.github_repository.full_name}:${c}"
      ]
    }
  }
}
