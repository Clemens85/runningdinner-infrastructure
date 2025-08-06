# This requires the runningdinner-functions CDK to be deployed first (with the specified topic name) !!!
data "aws_sns_topic" "route-optimization-notifications" {
  name = "route-optimization-notifications"
}

# The name is confusing, intially this was used for only mail webhhook notifications, but now
# this used in a general way for all webhook notifications (triggered by SNS)
data "aws_ssm_parameter" "mail-webhook-secret" {
  name = "/runningdinner/mail/webhook/secret"
}

resource "aws_sns_topic_subscription" "route-optimization-notifications-webhook" {
  topic_arn = data.aws_sns_topic.route-optimization-notifications.arn
  protocol  = "https"
  endpoint  = "https://${var.domain_name}/sse/dinnerrouteservice/v1/notify?webhookToken=${data.aws_ssm_parameter.mail-webhook-secret.value}"
}