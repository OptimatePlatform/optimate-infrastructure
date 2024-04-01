data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    sid    = "SecretsManager"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:ListSecrets",
      "secretsmanager:PutSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.pritunl_creds.arn
    ]
  }
}

resource "aws_iam_role" "this" {
  name               = var.vpn_name
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
  managed_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}


data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


resource "aws_iam_role_policy" "this" {
  name = var.vpn_name

  role = aws_iam_role.this.id

  policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_instance_profile" "this" {
  name = var.vpn_name
  role = aws_iam_role.this.name
}
