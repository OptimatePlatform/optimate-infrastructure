terraform {
  required_version = "1.5.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.10.0"
    }
  }
}