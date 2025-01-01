output "acm_certificate_arn" {
  description = "The ARN of the ACM Certificate ARN."
  value       = aws_acm_certificate.compoze_acm.arn
}
