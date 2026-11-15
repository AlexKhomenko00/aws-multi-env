resource "aws_service_discovery_private_dns_namespace" "this" {
  name = "staging.local"
  vpc  = module.vpc.vpc_id
}

resource "aws_service_discovery_service" "catalog" {
  name = "catalog"

  force_destroy = true

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}
