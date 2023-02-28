#data "aws_iam_user" "technical-user" {
#  user_name = "technical-user"
#}

resource "aws_sqs_queue" "geocode" {
  name = "geocode"
  redrive_policy = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.geocode-dl.arn}\",\"maxReceiveCount\":5}"
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

resource "aws_sqs_queue" "geocode-dl" {
  name = "geocode-dl"
  tags = local.common_tags
}
