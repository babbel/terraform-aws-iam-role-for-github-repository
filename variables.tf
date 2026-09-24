variable "context" {
  type = object({
    type   = string
    values = optional(list(string))
  })
  default = null

  validation {
    condition     = var.context == null ? true : contains(["environment", "pull_request", "branch", "tag"], var.context.type)
    error_message = "`context.type` must be one of: \"environment\", \"pull_request\", \"branch\", \"tag\"."
  }

  validation {
    condition = (
      var.context == null ? true :
      var.context.type == "pull_request" ? true :
      (var.context.values != null && length(coalesce(var.context.values, [])) > 0)
    )
    error_message = "`context.values` must be a non-empty list of strings, except when `context.type` is \"pull_request\"."
  }

  description = <<EOS
The context `type` can be one of

* `"environment"` (if the job references an environment)
* `"pull_request"` (if the job is triggered by a pull request event, but only if the job does not reference an environment)
* `"branch"` (if the job is triggered on a branch, but not via a pull request event and does not reference an environment)
* `"tag"` (if the job is triggered on a tag, but not via a pull request event and does not reference an environment)

For `"environment"`, `"branch"`, and `"tag"` types, `values` is a non-empty list of `"environment"`, `"branch"`, or `"tag"` names. The IAM role is assumable from any subject that matches any entry — all entries are OR'd together in the trust policy.

For `"pull_request"`, `values` is not used and shall be `null`.

For each entry in `values`, you can include multi-character match wildcards (`*`) and single-character match wildcards (`?`) anywhere in the string.

If you omit this variable, the IAM role will be assumable by any job triggered on this repository.

https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims
EOS
}

variable "default_tags" {
  type    = map(string)
  default = {}

  description = <<EOS
Map of tags assigned to all AWS resources created by this module.
EOS
}

variable "github_owner_id" {
  type    = number
  default = null

  description = <<EOS
Numeric ID of the GitHub organization or user owning `var.github_repository`.

Set this together with `var.github_repository.repo_id` to have the IAM role trust the immutable
subject claim `repo:OWNER@OWNER_ID/NAME@REPO_ID`, which GitHub issues for repositories created
after 2026-07-15 and for older repositories which opted in. Without both IDs, only the name-based
subject claim `repo:OWNER/NAME` is trusted, and repositories issuing immutable claims cannot
assume the IAM role.

The ID is available from the REST API (`gh api orgs/ORG --jq .id`) and from the
`github_organization` data source.

https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/
EOS
}

variable "github_repository" {
  type = object({
    full_name = string
    repo_id   = optional(number)
  })

  description = <<EOS
GitHub Actions workflows of this repositoy will be able to assume the IAM role
created by this module.

Instance of the `github_repository` resource or data source:

https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository
https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repository

`repo_id` is only required in combination with `var.github_owner_id`, in order to trust immutable
subject claims. Both the resource and the data source export it.
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

variable "iam_role_name" {
  type    = string
  default = null

  description = <<EOS
Custom name for the IAM role. If not provided, the name will be automatically
generated as `github-actions-<md5>` based on the assume role policy document.

Conflicts with `var.iam_role_name_prefix`.
EOS
}

variable "iam_role_name_prefix" {
  type    = string
  default = null

  description = <<EOS
Creates a unique name for the IAM role beginning with the specified prefix.

Conflicts with `var.iam_role_name`.

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role#name_prefix
EOS
}

variable "iam_role_tags" {
  type    = map(string)
  default = {}

  description = <<EOS
Map of tags assigned to the IAM role created by this module. Tags in this map will override tags in `var.default_tags`.

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role#tags
EOS
}

variable "max_session_duration" {
  type    = number
  default = null

  description = <<EOS
Maximum session duration (in seconds) that you want to set for the specified role. If you do not specify a value for this setting, the default maximum of one hour is applied. This setting can have a value from 1 hour to 12 hours.

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role#max_session_duration
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

variable "trust_immutable_subject" {
  type    = bool
  default = true

  description = <<EOS
Whether the IAM role trusts the immutable subject claim `repo:OWNER@OWNER_ID/NAME@REPO_ID`. It's
the only subject claim this module can trust, so this defaults to `true` and normally does not need
setting — it exists so a role can be planned without yet trusting anything (e.g. before
`github_owner_id`/`github_repository.repo_id` are known), by explicitly setting it to `false`.

https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/
EOS
}
