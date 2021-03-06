###
# Cloudfront requires client certificate to be created in us-east-1
# This certificate is only for the maintenance mode static site
###
resource "aws_acm_certificate" "covidportal_certificate" {
  provider    = aws.us-east-1
  domain_name = "portal.covid-hcportal.cdssandbox.xyz"
  subject_alternative_names = [
    "register.covid-hcportal.cdssandbox.xyz",
    "staging.covid-hcportal.cdssandbox.xyz"
  ]
  validation_method = "DNS"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.covidportal_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = "Z00598741VQJ24WH6COK9"
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.covidportal_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

###
# ELB requires client certificate to be created in the same region as the ELB
###
resource "aws_acm_certificate" "covidportal_certificate2" {
  domain_name               = "covid-hcportal.cdssandbox.xyz"
  subject_alternative_names = ["*.covid-hcportal.cdssandbox.xyz"]
  validation_method         = "DNS"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Add the certificates to the sub-subdomain hosted zone
resource "aws_route53_record" "cert_validation2" {
  for_each = {
    for dvo in aws_acm_certificate.covidportal_certificate2.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = "Z00598741VQJ24WH6COK9"
}

resource "aws_acm_certificate_validation" "cert2" {
  certificate_arn         = aws_acm_certificate.covidportal_certificate2.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation2 : record.fqdn]
}
