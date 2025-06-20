# datadog-opentelemetry-collector

In order to receive OpenTelemetry signals (traces and metrics) from Saleor Cloud environments customers must provide their OpenTelemetry endpoint. To avoid potential security issues we recommend not to make this endpoint open to internet and use AWS VPC PrivateLink. AWS’ docs: https://aws.amazon.com/privatelink/

This repository contains terraform module with example opentelemetry-collector deployment and AWS VPC PrivateLink.

**Setup guide:**

1. Saleor sets up an OTEL collector for customers.
2. Client creates secret with Datadog API Key in AWS Secrets manager.
3. Client sets up a Terraform module with OTEL collector.
4. Client shares VPC PrivateLink service name (tf module output) with Saleor.
5. Saleor sets up OTEL metrics export using client’s PrivateLink service name.

**Usage:**

```
module "otel_collector" {
  source = "github.com/saleor/datadog-opentelemetry-collector"

  name = "opentelemetry"

  network_cidr_block = "192.168.0.0/16"  # CIDR block different from Saleor Cloud
  availability_zones = [                 # Saleor Cloud K8S cluster AZs
      "eu-west-1a",
      "eu-west-1b",
      "eu-west-1c"
    ]
  allowed_aws_accounts = [ "XXXXXXXXXXXX" ]  # Saleor Cloud account id
  allowed_cidr_blocks  = [ "X.X.X.X/XX" ]    # Saleor Cloud K8S cluster VPC

  datadog_api_key_secret_name = "datadog_api_key" # AWS Secret name for Datadog API key
  otel_workers_count = 2
}

output "vpc_endpoint_service_name" {
  value = module.otel_collector.vpc_endpoint_service_name
}
```

**Module content:**

- **VPC network with security groups**
  Private network which allows ingress traffic only on OTLP port (4317) and only from other private networks (`allowed_cidr_blocks`). It must use same region and availability zones as Saleor Cloud.
- **AWS VPC service endpoint**
  Allows VPC network access from other AWS accounts (must include Saleor Cloud) using `service name`
- **Network load balancer**
  Private load balancer for OTEL collector deployment instances
- **OTEL collector deployment**
  Collects OpenTelemtry signals from Saleor Cloud and forwards them to Datadog.
  This example uses ECS Fargate for container deployment, but it can be replaced with Kubernetes deployment or EC2 instances. However, any kind of deployment should be attached to network load balancer as a target group.
