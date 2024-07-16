terraform {
  backend "s3" {
    bucket = "shared-169411831568-tfstate"
    key    = "staging/terraform.tfstate"
    region = "us-east-1"
  }
}