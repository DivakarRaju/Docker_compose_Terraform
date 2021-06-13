resource "aws_s3_bucket" "zip_file_bucket" {
  bucket = "sample-filebucket-terraform"
  #   acl    = "public-read-write"
#   provider = aws.local
}

data "archive_file" "ping_pong_file_archive" {
  type        = "zip"
  source_file = "../function/sample.py"
  output_path = "../function/sample.zip"
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
  #   filename      = data.archive_file.ping_pong_file_archive.output_path
  # filename = aws_s3_bucket_object.object.source
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