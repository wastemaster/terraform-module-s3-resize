###########################
# Variables
###########################

data "aws_caller_identity" "current" {}

###########################
# S3 bucket
###########################

locals {
  bucket_name = "${var.project_name}-${var.environment}-${var.bucket_name}"
}

locals {
  api_host = [
    "${split("/",aws_api_gateway_deployment.resize.invoke_url)}"]
}

resource "aws_s3_bucket" "b" {
  bucket = "${local.bucket_name}"
  acl    = "private"

  policy = <<EOF
{
  "Id": "bucket_policy_site",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "bucket_policy_site_main",
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${local.bucket_name}/*",
      "Principal": "*"
    }
  ]
}
EOF

  website {
    index_document = "index.html"

    routing_rules = <<EOF
[{
    "Condition": {
      "KeyPrefixEquals": "",
        "HttpErrorCodeReturnedEquals": "404"
    },
    "Redirect": {
      "Protocol": "https",
      "HostName": "${local.api_host[2]}",
        "ReplaceKeyPrefixWith": "${local.api_host[3]}${aws_api_gateway_resource.resource.path}?key=",
        "HttpRedirectCode": "307"
    }
}]
EOF
  }

  tags = "${var.tags}"
}

###########################
# CloudFront distribution
###########################
# TODO: cache default ttl for */crop/* and */resize/*
###########################

locals {
  s3_origin_id = "${var.project_name}-${var.environment}-${var.bucket_name}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = [
        "TLSv1.2"]
    }

    domain_name = "${local.bucket_name}.s3-website.${var.aws_region}.amazonaws.com"
    origin_id   = "${local.s3_origin_id}"
  }

  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"

  #  aliases = ["dev.mijnstekkie.nl"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  default_cache_behavior {
    allowed_methods  = [
      "GET",
      "HEAD"]
    cached_methods   = [
      "GET",
      "HEAD"]
    target_origin_id = "${local.s3_origin_id}"
    compress         = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
  }
  ordered_cache_behavior {
    path_pattern     = "*/crop/*"
    allowed_methods  = [
      "GET",
      "HEAD"]
    cached_methods   = [
      "GET",
      "HEAD"]
    target_origin_id = "${local.s3_origin_id}"
    compress         = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 31536000

    viewer_protocol_policy = "allow-all"
  }
  ordered_cache_behavior {
    path_pattern     = "*/resize/*"
    allowed_methods  = [
      "GET",
      "HEAD"]
    cached_methods   = [
      "GET",
      "HEAD"]
    target_origin_id = "${local.s3_origin_id}"
    compress         = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 31536000

    viewer_protocol_policy = "allow-all"
  }

  tags = "${var.tags}"

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

###########################
# API Gateway
###########################

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.project_name}-${var.environment}-api"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "resize"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.resource.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api.id}"
  resource_id             = "${aws_api_gateway_resource.resource.id}"
  http_method             = "${aws_api_gateway_method.method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda.arn}/invocations"
}

###########################
# Lambda
###########################

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}

resource "aws_api_gateway_deployment" "resize" {
  depends_on = [
    "aws_api_gateway_integration.integration"]

  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "${var.environment}"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [
        "lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_policy" "access" {
  name = "${var.project_name}-${var.environment}-lambda-access-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::${local.bucket_name}/*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "access" {
  name       = "${var.project_name}-${var.environment}-lambda-access-policy-attachment"
  roles      = [
    "${aws_iam_role.iam_for_lambda.name}"]
  policy_arn = "${aws_iam_policy.access.arn}"
}

resource "aws_lambda_function" "lambda" {
  filename         = "${path.module}/lambda.zip"
  function_name    = "${var.project_name}-${var.environment}-resize"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "index.handler"
  source_code_hash = "${base64sha256(file("${path.module}/lambda.zip"))}"
  runtime          = "nodejs12.x"
  memory_size      = 1536
  timeout          = 30

  environment {
    variables = {
      URL    = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
      #http://rmnl-dev-img.s3-website-eu-west-1.amazonaws.com/
      BUCKET = "${local.bucket_name}"
    }
  }

  tags = "${var.tags}"
}

###########################
# User
###########################

resource "aws_iam_user" "s3" {
  count = "${var.should_create_user ? 1 : 0}"
  name  = "${var.project_name}-${var.environment}-s3-img"
}

resource "aws_iam_access_key" "s3" {
  count = "${var.should_create_user ? 1 : 0}"
  user  = "${aws_iam_user.s3.name}"
}

resource "aws_iam_user_policy" "lb_ro" {
  count = "${var.should_create_user ? 1 : 0}"

  user = "${aws_iam_user.s3.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.b.bucket}",
        "arn:aws:s3:::${aws_s3_bucket.b.bucket}/*"
      ]
    }
  ]
}
EOF
}

