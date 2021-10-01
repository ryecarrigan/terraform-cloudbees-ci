resource "aws_acm_certificate" "certificate" {
  domain_name       = var.host_name
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

resource "aws_route53_record" "cname" {
  depends_on = [helm_release.ingress_nginx]

  name    = var.host_name
  records = [lookup(data.kubernetes_service.ingress_controller.status[0].load_balancer[0], "ingress")[0].hostname]
  ttl     = 60
  type    = "CNAME"
  zone_id = data.aws_route53_zone.domain_name.id
}

data "aws_route53_zone" "domain_name" {
  name = var.domain_name
}
