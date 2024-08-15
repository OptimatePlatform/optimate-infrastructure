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