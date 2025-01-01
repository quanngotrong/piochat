provider "aws" {
  region = var.aws_region
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = var.bucket_name
}

module "acm_dns_validation" {
  source      = "./modules/acm_dns_validation"
  domain_name = var.domain_name
}

output "acm_certificate_arn" {
  value = module.acm_dns_validation.acm_certificate_arn
}
