terraform {
  backend "s3" {
    bucket = "shared-169411831568-tfstate"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}