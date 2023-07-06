provider "aws" {
  region = "eu-central-1"
}

variable "slack_url" {}

resource "aws_lambda_function" "get_running_instances" {
  function_name = "GetRunningInstances"

  filename         = "lambda_function_payload.zip"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")
  handler          = "aws_tracker.main"
  runtime          = "python3.7"
  timeout          = 60
  role             = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_url
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })

  inline_policy {
    name   = "lambda_ec2_information"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1688633130582",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
  }
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_event_rule" "every_thursday" {
  name                = "every-thursday"
  schedule_expression = "cron(5 14 ? * 4 *)"
}

resource "aws_cloudwatch_event_target" "thursday_target" {
  rule = aws_cloudwatch_event_rule.every_thursday.name
  arn  = aws_lambda_function.get_running_instances.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_running_instances.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_thursday.arn
}


