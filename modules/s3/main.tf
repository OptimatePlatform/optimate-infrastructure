data "aws_iam_policy_document" "vpc_endpoint_bucket_policy" {
  count = var.vpc_endpoint_id != null ? 1 : 0

  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      module.s3_bucket.s3_bucket_arn,
      "${module.s3_bucket.s3_bucket_arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpce"

      values = [
        var.vpc_endpoint_id
      ]
    }
  }
}

data "aws_iam_policy_document" "combined" {
  source_policy_documents = compact(concat(
    [
      var.vpc_endpoint_id != null ? data.aws_iam_policy_document.vpc_endpoint_bucket_policy[0].json : ""
    ],
    var.user_provided_policies
  ))
}

# -----------------------------
# S3 bucket
# -----------------------------

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.1"

  bucket = var.bucket_name

  force_destroy = var.force_destroy

  # Block all public access
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets

  attach_policy                         = var.attach_policy
  policy                                = var.attach_policy ? data.aws_iam_policy_document.combined.json : null
  attach_elb_log_delivery_policy        = var.attach_elb_log_delivery_policy
  attach_lb_log_delivery_policy         = var.attach_lb_log_delivery_policy
  attach_access_log_delivery_policy     = var.attach_access_log_delivery_policy
  attach_deny_insecure_transport_policy = var.attach_deny_insecure_transport_policy
  attach_require_latest_tls_policy      = var.attach_require_latest_tls_policy
  attach_public_policy                  = var.attach_public_policy
  attach_inventory_destination_policy   = var.attach_inventory_destination_policy
  attach_analytics_destination_policy   = var.attach_analytics_destination_policy

  access_log_delivery_policy_source_buckets  = var.access_log_delivery_policy_source_buckets
  access_log_delivery_policy_source_accounts = var.access_log_delivery_policy_source_accounts

  acceleration_status = var.acceleration_status
  request_payer       = var.request_payer

  website = var.website

  cors_rule = var.cors_rule

  versioning = var.versioning

  logging = var.logging

  acl = var.acl

  owner                 = var.owner
  expected_bucket_owner = var.expected_bucket_owner

  lifecycle_rule = var.lifecycle_rule

  replication_configuration = var.replication_configuration

  server_side_encryption_configuration = var.server_side_encryption_configuration

  intelligent_tiering = var.intelligent_tiering

  object_lock_enabled       = var.object_lock_enabled
  object_lock_configuration = var.object_lock_configuration

  object_ownership         = var.object_ownership
  control_object_ownership = var.control_object_ownership

  metric_configuration = var.metric_configuration

  inventory_configuration           = var.inventory_configuration
  inventory_source_account_id       = var.inventory_source_account_id
  inventory_source_bucket_arn       = var.inventory_source_bucket_arn
  inventory_self_source_destination = var.inventory_self_source_destination

  analytics_configuration           = var.analytics_configuration
  analytics_source_account_id       = var.analytics_source_account_id
  analytics_source_bucket_arn       = var.analytics_source_bucket_arn
  analytics_self_source_destination = var.analytics_self_source_destination

  tags = var.tags
}
