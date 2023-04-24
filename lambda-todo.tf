resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.lambdas.id
  key    = "lambda.zip"
  source = data.archive_file.dummy.output_path
}

resource "aws_lambda_function" "test_lambda" {
  s3_bucket     = aws_s3_bucket.lambdas.id
  s3_key        = "lambda.zip"
  function_name = "test-lambda"
  handler       = "func"
  runtime       = "provided.al2"
  timeout       = 180
  role          = aws_iam_role.lambda_exec.arn
}
