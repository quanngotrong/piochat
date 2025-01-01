variable "aws_region" {
  description = "AWS Singapore region"
  type        = string
  default     = "ap-southeast-1"
}

variable "bucket_name" {
  description = "s3 bucket name"
  type        = string
  default     = "piochat-s3-quan-test"
}

variable "domain_name" {
  description = "domain name"
  type        = string
  default     = "ngotrongquanweb.xyz"
}
