provider "aws" {
  region = var.aws_region
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "s3" {
  source = "./modules/s3"
  bucket_name = var.bucket_name
}
