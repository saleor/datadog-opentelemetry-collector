resource "aws_vpc_endpoint_service" "otlp_privatelink" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.private_nlb.arn]
  tags = {
    Name = "${var.name}-privatelink"
  }
}

resource "aws_vpc_endpoint_service_allowed_principal" "allowed_aws_accounts" {
  for_each = toset(var.allowed_aws_accounts)

  vpc_endpoint_service_id = aws_vpc_endpoint_service.otlp_privatelink.id
  principal_arn           = "arn:aws:iam::${each.key}:root"
}
