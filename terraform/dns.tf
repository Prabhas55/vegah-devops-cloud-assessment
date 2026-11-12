# Route 53 failover routing (created only when domain_name is set).
# PRIMARY record is served while its health check passes; otherwise Route 53 answers with SECONDARY (DR).
data "aws_route53_zone" "main" {
  provider     = aws.dr
  count        = var.domain_name != "" ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_health_check" "primary" {
  provider          = aws.dr
  count             = var.domain_name != "" ? 1 : 0
  ip_address        = var.primary_ip
  port              = 80
  type              = "HTTP"
  resource_path     = "/api/health"
  request_interval  = 10
  failure_threshold = 3
  tags              = { Name = "vegah-primary-health", Project = "vegah-dr" }
}

resource "aws_route53_record" "primary" {
  provider        = aws.dr
  count           = var.domain_name != "" ? 1 : 0
  zone_id         = data.aws_route53_zone.main[0].zone_id
  name            = var.record_name == "" ? var.domain_name : "${var.record_name}.${var.domain_name}"
  type            = "A"
  ttl             = var.dns_ttl
  records         = [var.primary_ip]
  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary[0].id

  failover_routing_policy {
    type = "PRIMARY"
  }
}

resource "aws_route53_record" "secondary" {
  provider       = aws.dr
  count          = var.domain_name != "" ? 1 : 0
  zone_id        = data.aws_route53_zone.main[0].zone_id
  name           = var.record_name == "" ? var.domain_name : "${var.record_name}.${var.domain_name}"
  type           = "A"
  ttl            = var.dns_ttl
  records        = [aws_eip.dr.public_ip]
  set_identifier = "secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }
}
