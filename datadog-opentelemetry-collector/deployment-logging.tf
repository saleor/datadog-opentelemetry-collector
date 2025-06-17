resource "aws_cloudwatch_log_group" "log_group" {
  name              = var.name
  retention_in_days = 7
}


data "aws_iam_policy_document" "logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["${aws_cloudwatch_log_group.log_group.arn}:*"]
  }
}

resource "aws_iam_policy" "logging" {
  name   = "${var.name}-logging"
  policy = data.aws_iam_policy_document.logging.json
}
