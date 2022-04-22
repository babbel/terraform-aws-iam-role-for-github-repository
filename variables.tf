variable "additional_conditions" {
  type = map(string)
  default = {}

  description = <<EOS
Map of additional conditions from the OpenID token to check in the IAM role's
trust policy, e.g.

    {
      environment = "production"
    }

in order to ensure that the GitHub Actions workflow is running in context of a
GitHub Action environment named "production".

List of all available condition keys:

https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#understanding-the-oidc-token
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
  type = string
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
  type = map(string)
  default = {}

  description = <<EOS
Map of tags used on all AWS resources created by this module.
EOS
}
