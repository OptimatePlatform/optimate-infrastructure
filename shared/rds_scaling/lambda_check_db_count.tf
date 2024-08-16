data "archive_file" "check_db_count_lambda_package" {
  type        = "zip"
  source_file = "${path.module}/lambdas/scripts/check_db_count.py"
  output_path = "${path.module}/lambdas/packages/check_db_count.zip"
}


resource "aws_lambda_function" "check_db_count" {
  function_name = "check_db_count"
  description   = "Lambda for check count of databases in specified RDS instance and Create RDS instance if db count more than treshhold. Part of RDS Scaling Solution"
  role          = aws_iam_role.lambda_exec_check_db_count.arn
  handler       = "check_db_count.lambda_handler"
  architectures = var.lambda_architectures
  runtime       = var.lamba_runtime
  timeout       = 500

  filename         = data.archive_file.check_db_count_lambda_package.output_path
  source_code_hash = data.archive_file.check_db_count_lambda_package.output_base64sha256
  package_type     = "Zip"

  layers = [aws_lambda_layer_version.pymssql.arn]

  vpc_config {
    subnet_ids         = data.terraform_remote_state.networking.outputs.database_subnets
    security_group_ids = [data.terraform_remote_state.networking.outputs.shared_rds_mssql_main_sg_id]
  }

  environment {
    variables = {
      DB_COUNT_PER_RDS_TRESHOLD           = 25
      STATE_MACHINE_ARN                   = aws_sfn_state_machine.check_rds_status.arn
      COMMON_RDS_INFO_SECRET_NAME         = aws_secretsmanager_secret.latest_rds_instance.name
      COMMON_RDS_MASTER_CREDS_SECRET_NAME = aws_secretsmanager_secret.common_rds_master_creds.name

      RDS_INSTANCE_CLASS        = "db.t3.small"
      RDS_PORT                  = "1433"
      RDS_ENGINE                = "sqlserver-ex"
      RDS_ENGINE_VERSION        = "16.00.4105.2.v1"
      RDS_LICENSE_MODEL         = "license-included"
      RDS_STORAGE_TYPE          = "gp3"
      RDS_ALLOCATED_STORAGE     = "20"
      RDS_MAX_ALLOCATED_STORAGE = "50"
      RDS_DELETION_PROTECTION   = "" # empty string = false, other symbols = true
      RDS_SUBNET_GROUP_NAME     = data.terraform_remote_state.networking.outputs.database_subnet_group_name
      RDS_SECURITY_GROUP_ID     = data.terraform_remote_state.networking.outputs.shared_rds_mssql_main_sg_id
    }
  }
}

resource "aws_cloudwatch_event_rule" "lambda_check_db_count_rule" {
  name                = "lambda_check_db_count_schedule"
  schedule_expression = "rate(10 minutes)" # How often run check of databases count per latest RDS instance
}

resource "aws_cloudwatch_event_target" "check_db_count_target" {
  rule = aws_cloudwatch_event_rule.lambda_check_db_count_rule.name
  arn  = aws_lambda_function.check_db_count.arn
}

resource "aws_lambda_permission" "allow_eventbridge_check_db_count" {
  statement_id  = "AllowEventBridgeInvokeCheckDbCount"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.check_db_count.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_check_db_count_rule.arn
}



###################
####### IAM #######
###################
resource "aws_iam_role" "lambda_exec_check_db_count" {
  name = "lambda_exec_check_db_count"

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

resource "aws_iam_policy" "lambda_check_db_count_policy" {
  name = "lambda_check_db_count_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "rds:*"
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

resource "aws_iam_role_policy_attachment" "lambda_exec_check_db_count" {
  role       = aws_iam_role.lambda_exec_check_db_count.name
  policy_arn = aws_iam_policy.lambda_check_db_count_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_exec_check_db_count_logging" {
  role       = aws_iam_role.lambda_exec_check_db_count.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_exec_check_db_count_vpc" {
  role       = aws_iam_role.lambda_exec_check_db_count.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}