terraform {
  required_version = "1.5.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}