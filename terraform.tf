terraform {
  required_version = ">= 0.11.7"

  backend "s3" {
    bucket         = "terradatum-terraform-state"
    encrypt        = "true"
    region         = "us-west-2"
    dynamodb_table = "terradatum-terraform-locks"
    key            = "dev-usw2/msk-kafka/terraform.tfstate"
  }
}
