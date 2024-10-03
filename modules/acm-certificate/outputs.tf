output "certificate_arn" {
  value = aws_acm_certificate.this.arn
}

output "domain_name" {
  value = local.domain_name
}
