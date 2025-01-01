provider "aws" {
  region = var.aws_region
}

module "dynamodb" {
  source = "./modules/dynamodb"
}
