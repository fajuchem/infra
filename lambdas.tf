data "archive_file" "dummy" {
  output_path = "${path.module}/dist.zip"
  type        = "zip"
  source_file = "${path.module}/bootstrap"
}

resource "aws_s3_bucket" "lambdas" {
  bucket_prefix = "lambdas"
}

resource "aws_iam_role_policy_attachment" "iam_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.iam_policy.arn
}

resource "aws_iam_policy" "iam_policy" {
  name        = "lambda_access-policy"
  description = "IAM Policy"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::lambdas",
                "arn:aws:s3:::lambdas/*"
            ]
        },
        {
          "Action": [
            "autoscaling:Describe*",
            "cloudwatch:*",
            "logs:*",
            "sns:*"
          ],
          "Effect": "Allow",
          "Resource": "*"
        }
  ]
}
  EOF
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "lambda_exec" {
  name               = "serverless_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
