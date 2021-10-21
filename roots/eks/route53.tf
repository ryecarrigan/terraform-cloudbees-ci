locals {
  zone_name = length(var.zone_name) > 0 ? var.zone_name : var.certificate_domain_name
}

resource "aws_acm_certificate" "certificate" {
  domain_name       = var.certificate_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  depends_on = [aws_acm_certificate.certificate]

  name     = aws_acm_certificate.certificate.domain_validation_options.*.resource_record_name[0]
  records  = [aws_acm_certificate.certificate.domain_validation_options.*.resource_record_value[0]]
  ttl      = 60
  type     = aws_acm_certificate.certificate.domain_validation_options.*.resource_record_type[0]
  zone_id  = data.aws_route53_zone.domain_name.id
}

data "aws_route53_zone" "domain_name" {
  name = local.zone_name
}
