resource "aws_acm_certificate" "this" {
  domain_name       = length(var.subdomain) > 0 ? "${var.subdomain}.${var.domain_name}" : var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "this" {
  for_each = {for option in aws_acm_certificate.this.domain_validation_options : option.domain_name => option}
  name     = each.value["resource_record_name"]
  records  = [each.value["resource_record_value"]]
  ttl      = 60
  type     = each.value["resource_record_type"]
  zone_id  = data.aws_route53_zone.domain_name.id
}

data "aws_route53_zone" "domain_name" {
  name = var.domain_name
}
