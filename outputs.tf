output "s3_bucket_name" {
  value = "${local.bucket_name}"
}

output "s3_bucket_arn" {
  value = "${aws_s3_bucket.b.arn}"
}

output "s3_bucket_id" {
  value = "${aws_s3_bucket.b.id}}"
}

output "cloudfront_distribution" {
  value = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}

output "s3_user_access_key" {
  value = "${var.should_create_user ? aws_iam_access_key.s3.*.id[0] : ""}"
}

output "s3_user_secret_key" {
  value = "${var.should_create_user ? aws_iam_access_key.s3.*.secret[0] : ""}"
}

output "s3_region" {
  value = "${var.aws_region}"
}

output "s3-bucket-fe" {
  value = "${aws_s3_bucket.b.bucket_regional_domain_name}"
}
