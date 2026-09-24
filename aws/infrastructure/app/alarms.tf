# ---------------------------------------------------------------------------
# SNS topic for CloudWatch alarms -> email (SNS free tier: 1,000 email notifications/month)
# ---------------------------------------------------------------------------

resource "aws_sns_topic" "ops-alerts" {
  name = "runningdinner-ops-alerts-${var.stage}"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "ops-alerts-email" {
  topic_arn = aws_sns_topic.ops-alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ---------------------------------------------------------------------------
# Alarms (6 total - CloudWatch free tier covers 10 alarms/month per account)
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "ecs-cpu-high" {
  alarm_name          = "runningdinner-${var.stage}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS service CPU utilization above 80% for 15 minutes"
  treat_missing_data  = "notBreaching"
  dimensions = {
    ClusterName = aws_ecs_cluster.runningdinner.name
    ServiceName = aws_ecs_service.runningdinner-ecs-service.name
  }
  alarm_actions = [aws_sns_topic.ops-alerts.arn]
  ok_actions    = [aws_sns_topic.ops-alerts.arn]
  tags          = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs-memory-high" {
  alarm_name          = "runningdinner-${var.stage}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS service memory utilization above 80% for 15 minutes"
  treat_missing_data  = "notBreaching"
  dimensions = {
    ClusterName = aws_ecs_cluster.runningdinner.name
    ServiceName = aws_ecs_service.runningdinner-ecs-service.name
  }
  alarm_actions = [aws_sns_topic.ops-alerts.arn]
  ok_actions    = [aws_sns_topic.ops-alerts.arn]
  tags          = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ec2-status-check-failed" {
  alarm_name          = "runningdinner-${var.stage}-ec2-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EC2 app instance failed a status check (instance or system level)"
  treat_missing_data  = "notBreaching"
  dimensions = {
    InstanceId = aws_instance.runningdinner-appserver.id
  }
  alarm_actions = [aws_sns_topic.ops-alerts.arn]
  ok_actions    = [aws_sns_topic.ops-alerts.arn]
  tags          = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds-connections-high" {
  alarm_name          = "runningdinner-${var.stage}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 40
  alarm_description   = "RDS connection count above 40 for 15 minutes (db.t4g.micro default max is ~87)"
  treat_missing_data  = "notBreaching"
  dimensions = {
    DBInstanceIdentifier = local.rds_instance_identifier
  }
  alarm_actions = [aws_sns_topic.ops-alerts.arn]
  ok_actions    = [aws_sns_topic.ops-alerts.arn]
  tags          = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "backend-hikari-pending-connections" {
  alarm_name          = "runningdinner-${var.stage}-backend-hikari-pending"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "hikaricp.connections.pending.value"
  namespace           = "RunningDinner/Backend"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Threads have been waiting for a Hikari DB connection for 3 consecutive minutes"
  treat_missing_data  = "notBreaching"
  dimensions = {
    pool = "runningdinner-backend"
  }
  alarm_actions = [aws_sns_topic.ops-alerts.arn]
  ok_actions    = [aws_sns_topic.ops-alerts.arn]
  tags          = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "backend-heap-usage-high" {
  alarm_name          = "runningdinner-${var.stage}-backend-heap-usage-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 85
  alarm_description   = "Backend JVM heap usage above 85% for 3 consecutive minutes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ops-alerts.arn]
  ok_actions          = [aws_sns_topic.ops-alerts.arn]
  tags                = local.common_tags

  metric_query {
    id = "heap_used"
    metric {
      metric_name = "jvm.heap.used.value"
      namespace   = "RunningDinner/Backend"
      period      = 60
      stat        = "Average"
    }
  }

  metric_query {
    id = "heap_max"
    metric {
      metric_name = "jvm.heap.max.value"
      namespace   = "RunningDinner/Backend"
      period      = 60
      stat        = "Average"
    }
  }

  metric_query {
    id          = "heap_pct"
    expression  = "(heap_used / heap_max) * 100"
    label       = "Heap Usage %"
    return_data = true
  }
}
