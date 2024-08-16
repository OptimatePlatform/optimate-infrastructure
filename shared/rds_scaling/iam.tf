####### Step Function Create RDS instance #######
resource "aws_iam_role" "step_functions" {
  name = local.step_function_check_rds_status_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "step_functions" {
  name = local.step_function_check_rds_status_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction",
          "lambda:*",
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_functions" {
  role       = aws_iam_role.step_functions.name
  policy_arn = aws_iam_policy.step_functions.arn
}
