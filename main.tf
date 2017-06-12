provider "aws" {
  region = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

# IAM Role for Lambda function
resource "aws_iam_role" "helloworld_role" {
    name = "helloworld_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# AWS Lambda function
resource "aws_lambda_function" "helloworld" {
    filename = "helloworld.zip"
    function_name = "helloWorld"
    role = "${aws_iam_role.helloworld_role.arn}"
    handler = "helloWorld.handler"
    runtime = "nodejs6.10"
    timeout = 3
    source_code_hash = "${base64sha256(file("helloworld.zip"))}"
}

# API

resource "aws_api_gateway_rest_api" "HelloWorldAPI" {
  name        = "HelloWorldAPI"
  description = "Endpoint for the Hello World function"
}

# API Gateway Resource

resource "aws_api_gateway_resource" "HelloWorldResource" {
  rest_api_id = "${aws_api_gateway_rest_api.HelloWorldAPI.id}"
  parent_id   = "${aws_api_gateway_rest_api.HelloWorldAPI.root_resource_id}"
  path_part   = "helloworldresource"
}

# API Gateway POST Method

resource "aws_api_gateway_method" "HelloWorldPostMethod" {
  rest_api_id   = "${aws_api_gateway_rest_api.HelloWorldAPI.id}"
  resource_id   = "${aws_api_gateway_resource.HelloWorldResource.id}"
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration

resource "aws_api_gateway_integration" "HelloWorldPostIntegration" {
  rest_api_id = "${aws_api_gateway_rest_api.HelloWorldAPI.id}"
  resource_id = "${aws_api_gateway_resource.HelloWorldResource.id}"
  http_method = "${aws_api_gateway_method.HelloWorldPostMethod.http_method}"
  integration_http_method = "POST"
  type = "AWS"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.helloworld.arn}/invocations"
  request_templates = {
    "application/json" = <<REQUEST_TEMPLATE
{
  "name": "$input.params('name')"
}
REQUEST_TEMPLATE
  }
  passthrough_behavior = "WHEN_NO_TEMPLATES"
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${aws_api_gateway_rest_api.HelloWorldAPI.id}"
  resource_id = "${aws_api_gateway_resource.HelloWorldResource.id}"
  http_method = "${aws_api_gateway_method.HelloWorldPostMethod.http_method}"
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "HelloWorldPostIntegrationResponse" {
  depends_on  = ["aws_api_gateway_integration.HelloWorldPostIntegration"]
  rest_api_id = "${aws_api_gateway_rest_api.HelloWorldAPI.id}"
  resource_id = "${aws_api_gateway_resource.HelloWorldResource.id}"
  http_method = "${aws_api_gateway_method.HelloWorldPostMethod.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
  response_templates {
    "application/json" = ""
  }
}

# Lambda permissions

data "aws_caller_identity" "current" {}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.helloworld.arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.HelloWorldAPI.id}/*/${aws_api_gateway_method.HelloWorldPostMethod.http_method}/helloworldresource"
}
