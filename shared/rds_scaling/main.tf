resource "aws_dynamodb_table" "latest_rds_instance" {
  name         = "RDSInstances"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "instance_id"

  attribute {
    name = "instance_id"
    type = "S"
  }
  attribute {
    name = "secret_name"
    type = "S"
  }

  global_secondary_index {
    name               = "SecretNameIndex"
    hash_key           = "secret_name"
    projection_type    = "ALL"
  }
}



resource "aws_dynamodb_table_item" "rds_init" {
  table_name = aws_dynamodb_table.latest_rds_instance.name

  hash_key = "instance_id"

  item = <<ITEM
{
  "instance_id": {"S": "rds-instance-1"},
  "secret_name": {"S": "rds-secret-1"}
}
ITEM
}



#####################################
####### Lambda check_db_count #######
#####################################
locals {
  pymssql_lambda_layer_path = "${path.module}/lambdas/scripts/layers/pymssql"
}


resource "null_resource" "pymssql_layer" {
  provisioner "local-exec" {
    command = "pip install pymssql==2.3.0 --quiet --only-binary=:all: --target ${local.pymssql_lambda_layer_path}"
  }
}

data "archive_file" "lambda_pymssql_layer" {
  type        = "zip"
  source_dir  = local.pymssql_lambda_layer_path
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

data "archive_file" "check_db_count_lambda_package" {
  type        = "zip"
  source_file = "${path.module}/lambdas/scripts/check_db_count.py"
  output_path = "${path.module}/lambdas/packages/check_db_count.zip"
}


resource "aws_lambda_function" "check_db_count" {
  function_name = "check_db_count"
  description   = "Lambda for check count of databases in specified RDS instance. Part of RDS Scaling Solution"
  role          = aws_iam_role.lambda_exec_check_db_count.arn
  handler       = "lambda_function.lambda_handler"
  architectures = var.lambda_architectures
  runtime       = var.lamba_runtime

  filename         = data.archive_file.check_db_count_lambda_package.output_path
  source_code_hash = data.archive_file.check_db_count_lambda_package.output_base64sha256
  package_type     = "Zip"

 layers = [aws_lambda_layer_version.pymssql.arn]

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.latest_rds_instance.name
    }
  }
}

resource "aws_cloudwatch_event_rule" "lambda_check_db_count_rule" {
  name                = "lambda_check_db_count_schedule"
  schedule_expression = "rate(10 minutes)"
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


#################################################
####### Step Function Create RDS instance #######
#################################################

# resource "aws_sfn_state_machine" "create_rds_instance" {
#   name     = "create_rds_instance_state_machine"
#   role_arn = aws_iam_role.step_functions_role.arn

#   definition = jsonencode({
#     Comment = "State machine to create RDS instance if needed",
#     StartAt = "CheckDBCount",
#     States = {
#       CheckDBCount = {
#         Type     = "Task",
#         Resource = aws_lambda_function.check_db_count.arn,
#         Next     = "CreateRDSInstance",
#         Catch = [{
#           ErrorEquals = ["States.ALL"],
#           Next        = "Fail"
#         }]
#       },
#       CreateRDSInstance = {
#         Type     = "Task",
#         Resource = aws_lambda_function.create_rds_instance.arn,
#         End      = true,
#         Catch = [{
#           ErrorEquals = ["States.ALL"],
#           Next        = "Fail"
#         }]
#       },
#       Fail = {
#         Type  = "Fail",
#         Cause = "Error in state machine"
#       }
#     }
#   })
# }



##########################################
####### Lambda update_rds_instance #######
##########################################
# resource "aws_lambda_function" "update_rds_instance" {
#   function_name = "update_rds_instance"
#   description   = "Lambda for creating RDS instance. Part of RDS Scaling Solution"
#   role          = aws_iam_role.lambda_exec_update_rds_instance.arn
#   handler        = "lambda_function.lambda_handler"
#   architectures = var.lambda_architectures
#   runtime       = var.lamba_runtime

#   filename = "${path.module}/scripts/update_rds_instance.zip"

#   environment {
#     variables = {
#       DYNAMODB_TABLE_NAME = aws_dynamodb_table.latest_rds_instance.name
#     }
#   }
# }