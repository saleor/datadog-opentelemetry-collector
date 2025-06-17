# datadog-opentelemetry-collector

Terraform module with opentelemetry-collector receiving metrics from Saleor Cloud and exporting them to Datadog

Usage:

```
module "otel_collector" {
  source = "modules/datadog-opentelemetry-collector"

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
