resource "aws_acm_certificate" "app" {
  domain_name       = var.app_fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "app" {
  certificate_arn         = aws_acm_certificate.app.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}


resource "aws_route53_record" "app_alias" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.app_fqdn
  type    = "A"

  alias {
    name                   = module.malik_ecs.alb_dns_name
    zone_id                = module.malik_ecs.alb_zone_id
    evaluate_target_health = true
  }
}
