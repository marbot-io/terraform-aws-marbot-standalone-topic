terraform {
  required_version = ">= 0.12.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.48.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.2"
    }
  }
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}



resource "random_id" "id8" {
  byte_length = 8
}



resource "aws_sns_topic" "marbot" {
  count = var.enabled ? 1 : 0

  name_prefix = "marbot"
  tags        = var.tags
}

resource "aws_sns_topic_policy" "marbot" {
  count = var.enabled ? 1 : 0

  arn    = join("", aws_sns_topic.marbot[*].arn)
  policy = data.aws_iam_policy_document.topic_policy.json
}

data "aws_iam_policy_document" "topic_policy" {
  statement {
    sid       = "Sid1"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [join("", aws_sns_topic.marbot[*].arn)]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "budgets.amazonaws.com",
        "rds.amazonaws.com",
        "s3.amazonaws.com",
        "backup.amazonaws.com",
        "codestar-notifications.amazonaws.com",
        "devops-guru.amazonaws.com"
      ]
    }
  }

  statement {
    sid       = "Sid2"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [join("", aws_sns_topic.marbot[*].arn)]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement { # SES https://docs.aws.amazon.com/ses/latest/dg/configure-sns-notifications.html
    sid       = "Sid3"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [join("", aws_sns_topic.marbot[*].arn)]

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:Referer"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement { # Inspector https://docs.aws.amazon.com/inspector/v1/userguide/inspector_assessments.html#sns-topic
    sid       = "Sid4"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [join("", aws_sns_topic.marbot[*].arn)]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::646659390643:root",
        "arn:aws:iam::316112463485:root",
        "arn:aws:iam::166987590008:root",
        "arn:aws:iam::758058086616:root",
        "arn:aws:iam::162588757376:root",
        "arn:aws:iam::526946625049:root",
        "arn:aws:iam::454640832652:root",
        "arn:aws:iam::406045910587:root",
        "arn:aws:iam::537503971621:root",
        "arn:aws:iam::357557129151:root",
        "arn:aws:iam::146838936955:root",
        "arn:aws:iam::453420244670:root"
      ]
    }
  }
}

resource "aws_sns_topic_subscription" "marbot" {
  depends_on = [aws_sns_topic_policy.marbot]
  count      = var.enabled ? 1 : 0

  topic_arn              = join("", aws_sns_topic.marbot[*].arn)
  protocol               = "https"
  endpoint               = "https://api.marbot.io/${var.stage}/endpoint/${var.endpoint_id}"
  endpoint_auto_confirms = true
  delivery_policy        = <<JSON
{
  "healthyRetryPolicy": {
    "minDelayTarget": 1,
    "maxDelayTarget": 60,
    "numRetries": 100,
    "numNoDelayRetries": 0,
    "backoffFunction": "exponential"
  },
  "throttlePolicy": {
    "maxReceivesPerSecond": 1
  }
}
JSON
}



resource "aws_cloudwatch_event_rule" "monitoring_jump_start_connection" {
  depends_on = [aws_sns_topic_subscription.marbot]
  count      = (var.module_version_monitoring_enabled && var.enabled) ? 1 : 0

  name                = "marbot-standalone-topic-connection-${random_id.id8.hex}"
  description         = "Monitoring Jump Start connection. (created by marbot)"
  schedule_expression = "rate(30 days)"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "monitoring_jump_start_connection" {
  count = (var.module_version_monitoring_enabled && var.enabled) ? 1 : 0

  rule      = join("", aws_cloudwatch_event_rule.monitoring_jump_start_connection[*].name)
  target_id = "marbot"
  arn       = join("", aws_sns_topic.marbot[*].arn)
  input     = <<JSON
{
  "Type": "monitoring-jump-start-tf-connection",
  "Module": "standalone-topic",
  "Version": "0.5.0",
  "Partition": "${data.aws_partition.current.partition}",
  "AccountId": "${data.aws_caller_identity.current.account_id}",
  "Region": "${data.aws_region.current.name}"
}
JSON
}
