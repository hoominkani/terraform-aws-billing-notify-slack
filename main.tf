data "archive_file" "notify_slack" {
  type        = "zip"
  source_dir  = "lambda/notify_slack"
  output_path = "lambda/upload/notify_slack.zip"
}

resource "aws_lambda_function" "notify_slack" {
  filename         = "${data.archive_file.notify_slack.output_path}"
  function_name    = "notify_slack"
  role             = "${aws_iam_role.lambda_notify_slack.arn}"
  source_code_hash = "${data.archive_file.notify_slack.output_base64sha256}"
  handler          = "notify_slack.lambda_handler"
  runtime          = "python3.6"

  memory_size = 128
  timeout     = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = aws_ssm_parameter.slack_webhook_url.value
    }
  }
}

######### IAM ###########
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "lambda_basic_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_policy" {
  source_json = data.aws_iam_policy.lambda_basic_execution.policy

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt"
    ]

    resources = ["*"]
  }

  statement {
    sid       = "2"
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid       = "3"
    actions   = ["ce:GetCostAndUsage"]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "NotifySlackLambdaPolicy"
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_notify_slack.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role" "lambda_notify_slack" {
  name               = "NotifySlackLambdaRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${aws_lambda_function.notify_slack.function_name}"
}

resource "aws_kms_key" "lambda_key" {
  description             = "Notify Slack Lambda Function Customer Master Key"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "lambda_key_alias" {
  name          = "alias/notify-slack-lambda-key"
  target_key_id = aws_kms_key.lambda_key.id
}
####### SSM ############

resource "aws_ssm_parameter" "slack_webhook_url" {
  name        = "/billing/notify/slack/webhook_url"
  value       = var.webhook_url
  type        = "String"
  description = "Slack Webhook Url"

  lifecycle {
    ignore_changes = [value,tags]
  }
}

####### Cloudwatch Events ###########

# 毎月JST10時に通知
resource "aws_cloudwatch_event_rule" "event_rule" {
  name                = "notify_slack"
  schedule_expression = "cron(0 01 1 * ? *)"
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule = aws_cloudwatch_event_rule.event_rule.name
  arn  = aws_lambda_function.notify_slack.arn
}

output "rule_arn" {
  value = aws_cloudwatch_event_rule.event_rule.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event_rule.arn
}

####### variable ###########

variable "webhook_url" {
    default = ""
}