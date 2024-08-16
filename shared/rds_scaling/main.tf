###################################################
####### Common RDS info for latest instance #######
###################################################
resource "aws_secretsmanager_secret" "latest_rds_instance" {
  name = "/${var.env}/rds/latest_instance_scaling_solution"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "latest_rds_instance_init_data" {
  secret_id = aws_secretsmanager_secret.latest_rds_instance.id
  secret_string = jsonencode({
    rds_instance_host           = "shared-rds-mssql-main-2.cgq2xaluqbvg.eu-central-1.rds.amazonaws.com"
    rds_secret_name             = "/shared/rds/shared-rds-mssql-main-2/credentials"
    active_rds_creation_process = "false"
    new_rds_instance_id         = "none"
  })
}



##################################################
####### Common creds for new RDS instances #######
##################################################
resource "random_password" "common_rds_master_password" {
  length           = 32
  special          = true
  override_special = "!#()-_=+[]"
}

resource "aws_secretsmanager_secret" "common_rds_master_creds" {
  name        = "/${var.env}/rds/common_rds_master_creds"
  description = "Secret with master creds for new RDS instances. Part of RDS scaling solution"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "common_rds_master_creds" {
  secret_id = aws_secretsmanager_secret.common_rds_master_creds.id
  secret_string = jsonencode({
    username = "admin",
    password = random_password.common_rds_master_password.result
  })
}


####################################
####### Lambda Layer Pymssql #######
####################################
locals {
  lambda_pymssql_layer_path     = "${path.module}/lambdas/layers/pymssql"
  lambda_pymssql_lib_layer_path = "${local.lambda_pymssql_layer_path}/python"
}

resource "null_resource" "pymssql_layer" {
  provisioner "local-exec" {
    command = "pip install pymssql==2.3.0 --quiet --platform manylinux2014_x86_64 --only-binary=:all: --target ${local.lambda_pymssql_lib_layer_path}"
  }
}

data "archive_file" "lambda_pymssql_layer" {
  type        = "zip"
  source_dir  = local.lambda_pymssql_layer_path
  output_path = "${path.module}/lambdas/zip_archives/lambda_pymssql_layer.zip"

  depends_on = [null_resource.pymssql_layer]
}


resource "aws_lambda_layer_version" "pymssql" {
  layer_name          = "pymssql"
  filename            = data.archive_file.lambda_pymssql_layer.output_path
  source_code_hash    = data.archive_file.lambda_pymssql_layer.output_base64sha256
  compatible_runtimes = [var.lamba_runtime]

  lifecycle {
    create_before_destroy = true
  }
}



#################################################
####### Step Function Create RDS instance #######
#################################################
locals {
  step_function_check_rds_status_name = "${var.env}-check-rds-status"
}

resource "aws_sfn_state_machine" "check_rds_status" {
  name     = local.step_function_check_rds_status_name
  role_arn = aws_iam_role.step_functions.arn

  definition = <<JSON
{
  "Comment": "Check RDS status every 5 minutes",
  "StartAt": "CheckRDSStatus",
  "States": {
    "CheckRDSStatus": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.check_rds_status.arn}",
      "Next": "IsRDSAvailable",
      "Retry": [
        {
          "ErrorEquals": ["States.TaskFailed"],
          "IntervalSeconds": ${var.rds_instance_status_polling_frequency},
          "MaxAttempts": 20,
          "BackoffRate": 1.0
        }
      ]
    },
    "IsRDSAvailable": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.rds_status",
          "StringEquals": "available",
          "Next": "Success"
        }
      ],
      "Default": "WaitForRDS"
    },
    "WaitForRDS": {
      "Type": "Wait",
      "Seconds": 300,
      "Next": "CheckRDSStatus"
    },
    "Success": {
      "Type": "Succeed"
    }
  }
}
JSON
}
