variable "region" {
  description = "AWS region name"
  type        = string
  default     = "eu-central-1"
}

variable "env" {
  description = "The environment name"
  type        = string
  default     = "shared"
}

variable "lamba_runtime" {
  description = "Lambda functions ryntime"
  type        = string
  default     = "python3.12"
}

variable "lambda_architectures" {
  description = "Instruction set architecture for your Lambda function. Valid values are [\"x86_64\"] and [\"arm64\"]."
  type        = list(string)
  default     = ["x86_64"]
}
