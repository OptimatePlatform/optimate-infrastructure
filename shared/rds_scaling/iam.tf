# resource "aws_iam_role" "lambda_exec_update_rds_instance" {
#   name = "lambda_exec_update_rds_instance"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_policy" "lambda_dynamodb_policy" {
#   name = "lambda_dynamodb_policy"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = [
#           "dynamodb:PutItem",
#           "dynamodb:GetItem"
#         ],
#         Effect   = "Allow",
#         Resource = aws_dynamodb_table.rds_instances.arn
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda_exec_update_rds_instance" {
#   role       = aws_iam_role.lambda_exec_update_rds_instance.name
#   policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
# }

# resource "aws_iam_role_policy_attachment" "lambda_exec_update_rds_instance_logging" {
#   role       = aws_iam_role.lambda_exec_update_rds_instance.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }


# ############## Lambda check db count ##############
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

resource "aws_iam_policy" "lambda_check_db_policy" {
  name = "lambda_check_db_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:GetItem"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.latest_rds_instance.arn
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:ListTagsForResource"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_check_db_count" {
  role       = aws_iam_role.lambda_exec_check_db_count.name
  policy_arn = aws_iam_policy.lambda_check_db_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_exec_check_db_count_logging" {
  role       = aws_iam_role.lambda_exec_check_db_count.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# ####### Step Function Create RDS instance #######
# resource "aws_iam_role" "step_functions_role" {
#   name = "step_functions_role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect    = "Allow",
#         Principal = {
#           Service = "states.amazonaws.com"
#         },
#         Action    = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "step_functions_policy" {
#   role       = aws_iam_role.step_functions_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSStepFunctionsFullAccess"
# }