# We do not manage those SQS resources within Terraform, but they are managed by the CDK project for geocoding
# So we just import those URLs and pass them to the Parameter store so that they can transparently be read from our app (-> task definition)

data "aws_sqs_queue" "geocode-request" {
  name = "geocoding-request"
}
data "aws_sqs_queue" "geocode-response" {
  name = "geocoding-response"
}
# Not really SQS, but makes sense in here...
data "aws_lambda_function_url" "geocode-http-function-url" {
  function_name = "geocoding-http"
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

# Not really SQS, but makes sense in here...
resource "aws_ssm_parameter" "geocode-http-function-url" {
  type = "String"
  name = "/runningdinner/geocode-http-function/url"
  tags = local.common_tags
  value = data.aws_lambda_function_url.geocode-http-function-url.function_url
}