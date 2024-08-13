data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "shared-169411831568-tfstate"
    key    = "shared/networking/terraform.tfstate"
    region = "us-east-1"
  }
}