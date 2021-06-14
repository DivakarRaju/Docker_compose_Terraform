# zip the python file

data "archive_file" "ping_pong_file_archive" {
  type        = "zip"
  source_file = "./sample.py"
  output_path = "./sample.zip"
}

#Creating a s3 bucket
resource "aws_s3_bucket" "zip_file_bucket" {
  bucket = "sample-filebucket-terraform"
  acl    = "private"
}

# push the zip file to s3
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

# Lambda
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


# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "myapi"
  description = "Terraform Serverless Application Example"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy" {
  path_part   = "proxy"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "GET"
  type                    = "AWS"
  uri                     = aws_lambda_function.ping_pong.invoke_arn
}

resource "aws_api_gateway_deployment" "function_deployment" {
  depends_on  = [aws_api_gateway_integration.lambda]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "test"

}


# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ping_pong.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "null_resource" "api_access_url" {
    provisioner "local-exec" {
    command = "echo ${var.host}/restapis/${aws_api_gateway_rest_api.api.id}/${aws_api_gateway_deployment.function_deployment.stage_name}/_user_request_/${aws_api_gateway_resource.proxy.path_part}"
  }
  
}
