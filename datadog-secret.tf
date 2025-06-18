data "aws_secretsmanager_secret" "datadog_api_key" {
  name = var.datadog_api_key_secret_name
}

data "aws_iam_policy_document" "datadog_api_key_secret" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [data.aws_secretsmanager_secret.datadog_api_key.arn]
  }
}

resource "aws_iam_policy" "datadog_api_key_secret" {
  name   = "${var.name}-datadog-api-key-secret"
  policy = data.aws_iam_policy_document.datadog_api_key_secret.json
}
