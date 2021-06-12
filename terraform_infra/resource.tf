
data "archive_file" "ping_pong_file_archive" {
  type        = "zip"
  source_file = "../function/sample.py"
  output_path = "../function/sample.zip"
}

data "aws_iam_policy_document" "policy" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.policy.json
}

resource "aws_lambda_function" "ping_pong" {
  filename      = "../function/sample.zip"
  function_name = "ping_pong"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "sample.ping_pong"

  runtime = "python3.8"

}