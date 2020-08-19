resource "aws_budgets_budget" "budget" {
  count             = var.enable_budget ? 1 : 0
  name              = "${var.org_name}-Monthly Budget"
  budget_type       = "COST"
  limit_amount      = format("%.1f", var.budget_ammount) #https://github.com/terraform-providers/terraform-provider-aws/issues/10692
  limit_unit        = "USD"
  time_period_start = "${substr(timestamp(), 0, 5)}01-01_00:00"
  time_unit         = var.budget_time

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.budget_threshold_percentage
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_email]
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_updates.*.arn[0]]
  }
  cost_types {
    include_credit = false
  }
  lifecycle {
    ignore_changes = [
      time_period_start, notification
    ]
  }
}

resource "aws_sns_topic" "budget_updates" {
  count = var.enable_budget ? 1 : 0
  name  = "${var.org_name}-budget-updates"
}

resource "aws_sns_topic_policy" "default" {
  count = var.enable_budget ? 1 : 0
  arn   = aws_sns_topic.budget_updates.*.arn[0]

  policy = data.aws_iam_policy_document.sns_topic_policy_budget.*.json[0]
}

data "aws_iam_policy_document" "sns_topic_policy_budget" {
  count     = var.enable_budget ? 1 : 0
  policy_id = "__default_policy_ID"

  statement {
    actions = ["SNS:Publish"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }
    resources = [aws_sns_topic.budget_updates.*.arn[0]]
    sid       = "__default_statement_ID"
  }
}