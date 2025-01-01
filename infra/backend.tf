terraform {
  backend "s3" {
    bucket         = "quan-piochat-terraform-state-bucket"
    key            = "piochat/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table" # For state locking
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "quan-piochat-terraform-state-bucket"
  acl    = "private"
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

  hash_key = "LockID"
}
