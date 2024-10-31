data "aws_iam_policy_document" "route53_user_pol" {
  statement {
    sid    = "Route53ChangeAndListRecords"
    effect = "Allow"

    resources = [
      "arn:aws:route53:::change/*",
      "arn:aws:route53:::hostedzone/*",
    ]

    actions = [
      "route53:GetChange",
      "route53:ListResourceRecordSets",
    ]
  }
  statement {
    sid       = "ListRoute53Zones"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "route53:ListHostedZonesByName",
      "route53:ListHostedZones",
    ]
  }
  statement {
    sid       = "Route53ChangeResources"
    effect    = "Allow"
    resources = ["arn:aws:route53:::hostedzone/Z032984826129MWNGG6UZ"]

    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsRecordTypes"
      values = [
        "TXT",
      ]
    }
  }
}

module "user_proxmox" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = ">= 5"

  name                          = "bagend-proxmox"
  create_iam_user_login_profile = false
  create_iam_access_key         = true
}

resource "aws_iam_user_policy" "bagend-proxmox-route53" {
  name = "bagend-proxmox-route53"
  user = module.user_proxmox.iam_user_name

  policy = data.aws_iam_policy_document.route53_user_pol.json
}
