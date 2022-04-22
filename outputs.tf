output "this" {
  value = aws_iam_role.this

  description = <<EOS
IAM role which can be assumed via OpenID by a GitHub-repository-specific GitHub Actions workflow.
EOS
}
