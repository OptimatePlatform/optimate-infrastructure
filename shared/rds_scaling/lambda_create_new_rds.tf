data "archive_file" "create_new_rds_lambda_package" {
  type        = "zip"
  source_file = "${path.module}/lambdas/scripts/create_new_rds.py"
  output_path = "${path.module}/lambdas/packages/create_new_rds.zip"
}

resource "aws_lambda_function" "create_new_rds" {
  function_name = "create_new_rds"
  description   = "Lambda for creating new RDS instance. Part of RDS Scaling Solution"
  role          = aws_iam_role.lambda_exec_create_new_rds.arn
  handler       = "create_new_rds.lambda_handler"
  architectures = var.lambda_architectures
  runtime       = var.lamba_runtime
  timeout       = 300

  filename         = data.archive_file.create_new_rds_lambda_package.output_path
  source_code_hash = data.archive_file.create_new_rds_lambda_package.output_base64sha256
  package_type     = "Zip"

  environment {
    variables = {
      COMMON_RDS_MASTER_CREDS_SECRET_NAME = module.common_rds_master_creds.secret_id

      RDS_INSTANCE_CLASS = "db.t3.small"
      RDS_PORT           = "1433"
      RDS_ENGINE         = "sqlserver-ex"
      # RDS_MAJOR_ENGINE_VERSION  = "16.00"
      RDS_ENGINE_VERSION = "16.00.4105.2.v1"
      # RDS_FAMILY                = "sqlserver-ex-16.0"
      RDS_LICENSE_MODEL         = "license-included"
      RDS_STORAGE_TYPE          = "gp3"
      RDS_ALLOCATED_STORAGE     = "40"
      RDS_MAX_ALLOCATED_STORAGE = "50"

      RDS_SUBNET_GROUP_NAME = data.terraform_remote_state.networking.outputs.database_subnet_group_name
      RDS_SECURITY_GROUP_ID = data.terraform_remote_state.networking.outputs.shared_rds_mssql_main_sg_id
    }
  }
}



###################
####### IAM #######
###################
resource "aws_iam_role" "lambda_exec_create_new_rds" {
  name = "lambda_exec_create_new_rds"

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

resource "aws_iam_policy" "lambda_create_new_rds_policy" {
  name = "lambda_create_new_rds_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "rds:*",
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
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_create_new_rds" {
  role       = aws_iam_role.lambda_exec_create_new_rds.name
  policy_arn = aws_iam_policy.lambda_create_new_rds_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_exec_create_new_rds_logging" {
  role       = aws_iam_role.lambda_exec_create_new_rds.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# resource "aws_iam_role_policy_attachment" "lambda_exec_create_new_rds_rds_full_access" {
#   role       = aws_iam_role.lambda_exec_create_new_rds.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
# }