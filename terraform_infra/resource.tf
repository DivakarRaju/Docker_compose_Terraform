data "archive_file" "ping_pong_file_archive" {
  type        = "zip"
  source_file = "../function/sample.py"
  output_path = "../function/sample.zip"
}

resource "aws_s3_bucket" "zip_file_bucket" {
  bucket = "sample-filebucket-terraform"
    acl    = "private"
}
resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.zip_file_bucket.id
  key    = "sample.zip"
  source = data.archive_file.ping_pong_file_archive.output_path
}

resource "aws_iam_role" "iam_for_lambda_tf" {
  name = "iam_for_lambda_tf"

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

resource "aws_lambda_function" "ping_pong" {
  s3_bucket     = aws_s3_bucket.zip_file_bucket.id
  s3_key        = aws_s3_bucket_object.object.key
  function_name = "ping_pong"
  role          = aws_iam_role.iam_for_lambda_tf.arn
  handler       = "sample.ping_pong"

  runtime = "python3.8"

  depends_on = [
    data.archive_file.ping_pong_file_archive,
    aws_s3_bucket_object.object
  ]

}

# resource "aws_apigatewayv2_api" "aws_api" {
#   name          = "example-http-api"
#   protocol_type = "HTTP"
# }

# resource "aws_apigatewayv2_integration" "sample" {
#     api_id           = aws_apigatewayv2_api.aws_api.id
#   integration_type = "AWS"

#   connection_type           = "INTERNET"
#   content_handling_strategy = "CONVERT_TO_TEXT"
#   description               = "Ping Pong Function Integration"
#   integration_method        = "GET"
#   integration_uri           = aws_lambda_function.ping_pong.invoke_arn
# #   passthrough_behavior      = "WHEN_NO_MATCH"
# }

# resource "aws_apigatewayv2_route" "api_route" {
#     api_id = aws_apigatewayv2_api.aws_api.id
#     route_key = 
#     target = aws_apigatewayv2_integration.sample.id
# }


# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "myapi"
  description = "Terraform Serverless Application Example"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "{resource+}"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ping_pong.invoke_arn
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ping_pong.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "function_deployment" {
  depends_on  = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
}

output "base_url" {
    value = aws_api_gateway_deployment.function_deployment.invoke_url
  
}