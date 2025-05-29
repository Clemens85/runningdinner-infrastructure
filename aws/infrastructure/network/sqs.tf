# We do not manage those SQS resources within Terraform, but they are managed by the CDK project for geocoding
# So we just import those URLs and pass them to the Parameter store so that they can transparently be read from our app (-> task definition)

data "aws_sqs_queue" "geocode-request" {
  name = "geocoding-request"
}
data "aws_sqs_queue" "geocode-response" {
  name = "geocoding-response"
}

resource "aws_ssm_parameter" "geocode-request-url" {
  type = "String"
  name = "/runningdinner/geocode-request/sqs/url"
  tags = local.common_tags
  value = data.aws_sqs_queue.geocode-request.url
}

resource "aws_ssm_parameter" "geocode-response-url" {
  type = "String"
  name = "/runningdinner/geocode-response/sqs/url"
  tags = local.common_tags
  value = data.aws_sqs_queue.geocode-response.url
}