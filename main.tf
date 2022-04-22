locals {
  conditions = merge(var.additional_conditions, {
    aud        = var.openid_audience
    repository = var.github_repository.full_name
  })
}

resource "aws_iam_role" "this" {
  name = "github-actions-${md5(jsonencode(local.conditions))}"

  assume_role_policy = data.aws_iam_policy_document.this.json

  tags = var.tags
}

data "aws_iam_policy_document" "this" {
  statement {
    principals {
      type        = "Federated"
      identifiers = [var.iam_openid_connect_provider.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    dynamic "condition" {
      for_each = local.conditions

      content {
        variable = "token.actions.githubusercontent.com:${condition.key}"
        test     = "StringEquals"
        values   = [condition.value]
      }
    }
  }
}
