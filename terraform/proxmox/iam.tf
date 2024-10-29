data "aws_iam_policy_document" "route53_lynggaardjensen_access" {
  statement {
    sid       = "Route53Change"
    effect    = "Allow"
    resources = ["arn:aws:route53:::change/*"]

    actions = [
      "route53:GetChange"
    ]
  }
  statement {
    sid       = "ListRoute53Zones"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "route53:ListHostedZonesByName",
    ]
  }
  statement {
    sid       = "Route53ChangeResources"
    effect    = "Allow"
    resources = ["arn:aws:route53:::hostedzone/Z032984826129MWNGG6UZ"]

    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]
  }
}

module "user_externaldns" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = ">= 5"

  name                          = "bagend-externaldns"
  create_iam_user_login_profile = false
  create_iam_access_key         = true
}

resource "aws_iam_user_policy" "externaldns_inline_pol" {
  name = "route53-lynggaardjensencom"
  user = module.user_externaldns.iam_user_name

  policy = data.aws_iam_policy_document.route53_lynggaardjensen_access.json
}
