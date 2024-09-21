locals {
  context = (
    var.context == null
    ? "*"
    : (
      var.context.type == "environment"
      ? "environment:${var.context.value}"
      : (
        var.context.type == "pull_request"
        ? "pull_request"
        : (
          var.context.type == "branch"
          ? "ref:refs/heads/${var.context.value}"
          : (
            var.context.type == "tag"
            ? "ref:refs/tags/${var.context.value}"
            : "invalid_context_type"
          )
        )
      )
    )
  )
}

resource "aws_iam_role" "this" {
  name = "github-actions-${md5(data.aws_iam_policy_document.this.json)}"

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
      values   = ["repo:${var.github_repository.full_name}:${local.context}"]
    }
  }
}
