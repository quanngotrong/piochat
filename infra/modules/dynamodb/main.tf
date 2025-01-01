# Users Table
resource "aws_dynamodb_table" "users" {
  name           = "Users"
  billing_mode   = "PAY_PER_REQUEST"

  hash_key       = "username"

  attribute {
    name = "username"
    type = "S"
  }

  tags = {
    Environment = "Production"
  }
}

# Messages Table
resource "aws_dynamodb_table" "messages" {
  name           = "Messages"
  billing_mode   = "PAY_PER_REQUEST"

  hash_key       = "conversationId"
  range_key      = "createdAt"

  attribute {
    name = "conversationId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  tags = {
    Environment = "Production"
  }
}

# Conversations Table
resource "aws_dynamodb_table" "conversations" {
  name           = "Conversations"
  billing_mode   = "PAY_PER_REQUEST"

  hash_key       = "conversationId"

  attribute {
    name = "conversationId"
    type = "S"
  }

  tags = {
    Environment = "Production"
  }
}
