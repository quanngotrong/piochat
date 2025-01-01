output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value = aws_subnet.public[*].id
}
