Terraform Module - S3 Resize
============================

Creates S3 bucket + Cloudfront for storing and distributing publicly available images + API Gateway endpoints for resizing and cropping these images using AWS Lambda.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region |  | string | n/a | yes |
| bucket\_name | Name of the bucket. Full bucket name will consist of project_name-environment-bucket_name | string | n/a | yes |
| environment |  | string | n/a | yes |
| project\_name |  | string | n/a | yes |
| should\_create\_user | Specify whether the module should create new user for the S3 bucket. | string | `"true"` | no |
| tags | Tags to apply to each taggable resource | map | `<map>` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudfront\_distribution |  |
| s3-bucket-fe |  |
| s3\_bucket\_arn |  |
| s3\_bucket\_id |  |
| s3\_bucket\_name |  |
| s3\_region |  |
| s3\_user\_access\_key |  |
| s3\_user\_secret\_key |  |

