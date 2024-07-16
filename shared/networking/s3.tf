data "aws_caller_identity" "current" {}

module "s3" {
  source = "../../modules/s3"

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  bucket_name = "${var.env}-s3-commonpurpose-${var.region}-${data.aws_caller_identity.current.account_id}"

  attach_policy          = true
  user_provided_policies = [data.aws_iam_policy_document.static.json]
}

data "aws_iam_policy_document" "static" {

  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::${var.env}-s3-commonpurpose-${var.region}-${data.aws_caller_identity.current.account_id}/files/*"
    ]
  }
}



module "s3_cicd_artifacts" {
  source = "../../modules/s3"

  bucket_name = "${var.env}-s3-cicd-artifacts-${var.region}-${data.aws_caller_identity.current.account_id}"
}