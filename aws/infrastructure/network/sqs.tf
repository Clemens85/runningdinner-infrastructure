#data "aws_iam_user" "technical-user" {
#  user_name = "technical-user"
#}

resource "aws_sqs_queue" "geocode-participant" {
  name = "geocode-participant"
  redrive_policy = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.geocode-participant-dl.arn}\",\"maxReceiveCount\":5}"
  tags = local.common_tags
#  policy = <<POLICY
#{
#   "Version": "2012-10-17",
#   "Statement": [{
#      "Effect": "Allow",
#      "Action": "sqs:*",
#      "Resource": "arn:aws:sqs:*:geocode*",
#      "Principal": {
#        "AWS": [
#          "${data.aws_iam_user.technical-user.arn}"
#        ]
#      }
#   }]
#}
#  POLICY
}

resource "aws_sqs_queue" "geocode-participant-dl" {
  name = "geocode-participant-dl"
  tags = local.common_tags
}

resource "aws_ssm_parameter" "geocode-participant-arn" {
  type = "String"
  name = "/runningdinner/geocode-participant/sqs/arn"
  tags = local.common_tags
  value = aws_sqs_queue.geocode-participant.arn
}
