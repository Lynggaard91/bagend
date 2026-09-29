data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "eso_ssm_pol" {
  statement {
    sid    = "ReadBagendParameters"
    effect = "Allow"

    resources = [
      "arn:aws:ssm:eu-west-1:${data.aws_caller_identity.current.account_id}:parameter/bagend/*",
    ]

    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
  }
}

module "user_eso" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam//modules/iam-user?ref=v6.4.0"

  name                 = "bagend-eso"
  create_login_profile = false
  create_access_key    = true
}

resource "aws_iam_user_policy" "bagend-eso-ssm" {
  name = "bagend-eso-ssm"
  user = module.user_eso.name

  policy = data.aws_iam_policy_document.eso_ssm_pol.json
}

resource "aws_ssm_parameter" "eso_access_key_id" {
  name  = "/bagend/eso/access_key_id"
  type  = "String"
  value = module.user_eso.access_key_id
}

resource "aws_ssm_parameter" "eso_secret_access_key" {
  name  = "/bagend/eso/secret_access_key"
  type  = "SecureString"
  value = module.user_eso.access_key_secret
}
