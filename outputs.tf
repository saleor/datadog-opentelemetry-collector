output "vpc_endpoint_service_name" {
  value = aws_vpc_endpoint_service.otlp_privatelink.service_name
}
