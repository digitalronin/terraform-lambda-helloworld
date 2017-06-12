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


