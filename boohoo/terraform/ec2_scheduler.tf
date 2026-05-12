# ─────────────────────────────────────────────
# EC2 Auto Start/Stop Scheduler
# ─────────────────────────────────────────────

# IAM Role for EC2 scheduler Lambdas
resource "aws_iam_role" "ec2_scheduler_role" {
  name = "BoohooEC2SchedulerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_scheduler_policy" {
  name = "EC2StartStopPolicy"
  role = aws_iam_role.ec2_scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Start Lambda
resource "aws_lambda_function" "ec2_start" {
  function_name = "boohoo-ec2-start"
  role          = aws_iam_role.ec2_scheduler_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

  filename         = "${path.module}/../dist/ec2_start.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/ec2_start.zip")

  environment {
    variables = {
      INSTANCE_ID = aws_instance.airflow.id
    }
  }
}

# Stop Lambda
resource "aws_lambda_function" "ec2_stop" {
  function_name = "boohoo-ec2-stop"
  role          = aws_iam_role.ec2_scheduler_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

  filename         = "${path.module}/../dist/ec2_stop.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/ec2_stop.zip")

  environment {
    variables = {
      INSTANCE_ID = aws_instance.airflow.id
    }
  }
}

# EventBridge: Start at 1:00 AM UTC on Mon/Wed/Fri only
resource "aws_cloudwatch_event_rule" "ec2_start_schedule" {
  name                = "BoohooAirflowStart"
  description         = "Start Airflow EC2 at 1:00 AM UTC Mon/Wed/Fri"
  schedule_expression = "cron(0 1 ? * MON,WED,FRI *)"
}

resource "aws_cloudwatch_event_target" "ec2_start_target" {
  rule      = aws_cloudwatch_event_rule.ec2_start_schedule.name
  target_id = "boohoo-ec2-start"
  arn       = aws_lambda_function.ec2_start.arn
}

resource "aws_lambda_permission" "allow_eventbridge_start" {
  statement_id  = "AllowEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_start.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_start_schedule.arn
}

# EventBridge: Stop at 3:00 AM UTC on Mon/Wed/Fri (pipeline finishes ~02:30)
resource "aws_cloudwatch_event_rule" "ec2_stop_schedule" {
  name                = "BoohooAirflowStop"
  description         = "Stop Airflow EC2 at 3:00 AM UTC Mon/Wed/Fri"
  schedule_expression = "cron(0 3 ? * MON,WED,FRI *)"
}

resource "aws_cloudwatch_event_target" "ec2_stop_target" {
  rule      = aws_cloudwatch_event_rule.ec2_stop_schedule.name
  target_id = "boohoo-ec2-stop"
  arn       = aws_lambda_function.ec2_stop.arn
}

resource "aws_lambda_permission" "allow_eventbridge_stop" {
  statement_id  = "AllowEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_stop.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_stop_schedule.arn
}
