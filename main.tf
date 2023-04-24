#resource "aws_lambda_function" "momentum_api" {
#  function_name = "momentum_api"
#  publish       = true
#  role          = aws_iam_role.lambda_exec.arn
#
#  handler = "func"
#  runtime = "provided"
#
#  # dummy package, package is delegated to CI pipeline
#  filename = data.archive_file.dummy.output_path
#  lifecycle {
#    ignore_changes = [s3_key, s3_bucket, layers, filename]
#  }
#}

#------------------------------------
#             Database               |
#------------------------------------

#resource "aws_kms_key" "db" {
#  description = "Database credentials"
#}

#resource "aws_db_instance" "db" {
#  allocated_storage    = 20
#  engine               = "postgres"
#  instance_class       = "db.t3.micro"
#  username             = "postgres"
#  manage_master_user_password   = true
#  master_user_secret_kms_key_id = aws_kms_key.db.key_id
#  skip_final_snapshot  = true
#  publicly_accessible = true
#}
#
#resource "aws_lambda_function" "momentum_api" {
#  function_name = "momentum_api"
#
#  # The bucket name as created earlier with "aws s3api create-bucket"
#  s3_bucket = "terraform-serverless-example"
#  s3_key    = "v1.0.0/example.zip"
#
#  # "main" is the filename within the zip file (main.js) and "handler"
#  # is the name of the property under which the handler function was
#  # exported in that file.
#  handler = "func"
#  runtime = "provided"
#
#  role = "${aws_iam_role.lambda_exec.arn}"
#}
