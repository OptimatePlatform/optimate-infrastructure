data "aws_caller_identity" "current" {}

module "s3" {
  source = "../../modules/s3"

  bucket_name = "${var.env}-s3-commonpurpose-${var.region}-${data.aws_caller_identity.current.account_id}"
}
