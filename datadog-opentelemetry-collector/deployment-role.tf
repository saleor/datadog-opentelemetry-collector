data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task" {
  name               = "${var.name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "logging" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.logging.arn
}

resource "aws_iam_role_policy_attachment" "datadog_api_key_secret" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.datadog_api_key_secret.arn
}

