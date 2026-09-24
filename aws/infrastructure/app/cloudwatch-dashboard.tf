# RDS identifier is a fixed literal (see database/rds.tf) - not stage-suffixed since dev/prod are separate accounts.
locals {
  rds_instance_identifier = "runningdinner-db"
}

resource "aws_cloudwatch_dashboard" "runningdinner" {
  dashboard_name = "runningdinner-${var.stage}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "alarm"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title = "Alarm Status"
          alarms = [
            aws_cloudwatch_metric_alarm.ecs-cpu-high.arn,
            aws_cloudwatch_metric_alarm.ecs-memory-high.arn,
            aws_cloudwatch_metric_alarm.ec2-status-check-failed.arn,
            aws_cloudwatch_metric_alarm.rds-connections-high.arn,
            aws_cloudwatch_metric_alarm.backend-hikari-pending-connections.arn,
            aws_cloudwatch_metric_alarm.backend-heap-usage-high.arn
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ECS Service - CPU & Memory Utilization (%)"
          view   = "timeSeries"
          region = var.region
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.runningdinner.name, "ServiceName", aws_ecs_service.runningdinner-ecs-service.name],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.runningdinner.name, "ServiceName", aws_ecs_service.runningdinner-ecs-service.name]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "EC2 App Server - Network Traffic (Bytes)"
          view   = "timeSeries"
          region = var.region
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.runningdinner-appserver.id],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.runningdinner-appserver.id]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "RDS - Database Connections"
          view   = "timeSeries"
          region = var.region
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", local.rds_instance_identifier]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Backend - JVM Heap Memory (Bytes)"
          view   = "timeSeries"
          region = var.region
          stat   = "Average"
          period = 60
          # Micrometer's CloudWatchMeterRegistry appends ".value" to Gauge metric names on publish:
          metrics = [
            ["RunningDinner/Backend", "jvm.heap.used.value"],
            ["RunningDinner/Backend", "jvm.heap.max.value"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "Backend - JVM Live Threads"
          view   = "timeSeries"
          region = var.region
          stat   = "Average"
          period = 60
          metrics = [
            ["RunningDinner/Backend", "jvm.threads.live.value"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "Backend - Hikari DB Connection Pool"
          view   = "timeSeries"
          region = var.region
          stat   = "Average"
          period = 60
          # Micrometer's CloudWatchMeterRegistry appends ".value" to Gauge metric names on publish, and Hikari
          # metrics carry a "pool" dimension (see spring.datasource.hikari.pool-name in application.properties):
          metrics = [
            ["RunningDinner/Backend", "hikaricp.connections.active.value", "pool", "runningdinner-backend"],
            ["RunningDinner/Backend", "hikaricp.connections.idle.value", "pool", "runningdinner-backend"],
            ["RunningDinner/Backend", "hikaricp.connections.pending.value", "pool", "runningdinner-backend"]
          ]
        }
      }
    ]
  })
}
