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
      RDS_PORT = data.terraform_remote_state.databases.outputs.rds_port
      DB_ENGINE = data.terraform_remote_state.databases.outputs.rds_port
      DB_SUBNET_GROUP_NAME = data.terraform_remote_state.networking.outputs.database_subnets
      VpcSecurityGroupId   = data.terraform_remote_state.networking.outputs.shared_rds_mssql_main_sg_id
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

resource "aws_iam_role_policy_attachment" "lambda_exec_create_new_rds_logging" {
  role       = aws_iam_role.lambda_exec_create_new_rds.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_exec_create_new_rds_rds_full_access" {
  role       = aws_iam_role.lambda_exec_create_new_rds.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}