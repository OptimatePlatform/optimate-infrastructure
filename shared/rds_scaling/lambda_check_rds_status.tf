data "archive_file" "check_rds_status_lambda_package" {
  type        = "zip"
  source_file = "${path.module}/lambdas/scripts/check_rds_status.py"
  output_path = "${path.module}/lambdas/packages/check_rds_status.zip"
}

locals {
  check_rds_status_lambda_name = "${var.env}-check-rds-status-lambda"
}

resource "aws_lambda_function" "check_rds_status" {
  function_name = local.check_rds_status_lambda_name
  description   = "Lambda for check status of new RDS instance. Part of RDS Scaling Solution"
  role          = aws_iam_role.lambda_exec_check_rds_status.arn
  handler       = "check_rds_status.lambda_handler"
  architectures = var.lambda_architectures
  runtime       = var.lamba_runtime
  timeout       = 500

  filename         = data.archive_file.check_rds_status_lambda_package.output_path
  source_code_hash = data.archive_file.check_rds_status_lambda_package.output_base64sha256
  package_type     = "Zip"

  layers = [aws_lambda_layer_version.pymssql.arn]

  vpc_config {
    subnet_ids         = data.terraform_remote_state.networking.outputs.database_subnets
    security_group_ids = [data.terraform_remote_state.networking.outputs.shared_rds_mssql_main_sg_id]
  }

  environment {
    variables = {
      COMMON_RDS_INFO_SECRET_NAME         = aws_secretsmanager_secret.latest_rds_instance.name
      COMMON_RDS_MASTER_CREDS_SECRET_NAME = aws_secretsmanager_secret.common_rds_master_creds.name
    }
  }
}



###################
####### IAM #######
###################
resource "aws_iam_role" "lambda_exec_check_rds_status" {
  name = local.check_rds_status_lambda_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_check_rds_status_policy" {
  name = local.check_rds_status_lambda_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:ListTagsForResource"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecrets"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:UpdateSecret",
          "secretsmanager:PutSecretValue"
        ],
        Effect   = "Allow",
        Resource = aws_secretsmanager_secret.latest_rds_instance.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_check_rds_status" {
  role       = aws_iam_role.lambda_exec_check_rds_status.name
  policy_arn = aws_iam_policy.lambda_check_rds_status_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_exec_check_rds_status_logging" {
  role       = aws_iam_role.lambda_exec_check_rds_status.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_exec_check_rds_status_vpc" {
  role       = aws_iam_role.lambda_exec_check_rds_status.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}