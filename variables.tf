variable "context" {
  type = object({
    type  = string
    value = string
  })
  default = null

  description = <<EOS
The context `type` can be one of

* `"environment"` (if the job references an environment)
* `"pull_request"` (if the job is triggered by a pull request event, but only if the job does not reference an environment)
* `"branch"` (if the job is triggered on a branch, but not via a pull request event and does not reference an environment)
* `"tag"` (if the job is triggered on a tag, but not via a pull request event and does not reference an environment)

and the `value` specified the corresponding `"environment"`, `"branch"`, or `"tag"` name. For `"pull_request"`, `value` is not used and shall be `null`.

For `value`, you can include multi-character match wildcards (`*`) and single-character match wildcards (`?`) anywhere in the string.

If you omit this variable, the IAM role will be assumable by any job triggered on this repository.

https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims
EOS
}

variable "github_repository" {
  type = object({
    full_name = string
  })

  description = <<EOS
GitHub Actions workflows of this repositoy will be able to assume the IAM role
created by this module.

Instance of the `github_repository` resource or data source:

https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository
https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repository
EOS
}

variable "iam_openid_connect_provider" {
  type = object({
    arn = string
  })

  description = <<EOS
The OpenID Connect provider for `token.actions.githubusercontent.com`. It must
include `var.openid_audience` in its `client_id_list` attribute.

Instance of the `aws_iam_openid_connect_provider` resource or data source:

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider
EOS
}

variable "openid_audience" {
  type    = string
  default = "sts.amazonaws.com"

  description = <<EOS
Value for the `aud` (audience) condition passed via the OpenID token from the
GitHub Actions workflow to the assumed IAM role.

The default value in this module corresponds with the default value passed by
the `aws-actions/configure-aws-credentials` GitHub Action.

https://github.com/aws-actions/configure-aws-credentials
EOS
}

variable "tags" {
  type    = map(string)
  default = {}

  description = <<EOS
Map of tags used on all AWS resources created by this module.
EOS
}
