Terraform Module - S3 Resize
============================

Creates S3 bucket + Cloudfront for storing and distributing publicly available images + API Gateway endpoints for resizing and cropping these images using AWS Lambda.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region | Region where the resources will be created | string | n/a | yes |
| bucket\_name | Name of the bucket. Full bucket name will consist of project_name-environment-bucket_name | string | n/a | yes |
| environment | The name of the environment | string | n/a | yes |
| project\_name | Project name | string | n/a | yes |
| should\_create\_user | Specify whether the module should create new user for the S3 bucket. | string | `"true"` | no |
| tags | Tags to apply to each taggable resource | map | `<map>` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudfront\_distribution\_domain |  |
| s3\_bucket\_arn |  |
| s3\_bucket\_domain\_name |  |
| s3\_bucket\_id |  |
| s3\_bucket\_name |  |
| s3\_region |  |
| s3\_user\_access\_key |  |
| s3\_user\_secret\_key |  |



## Notes - NPM installation for AWS Lambda

### To install Sharp library with binary compiled for AWS AMI, use this command
```
env npm_config_arch=x64 npm_config_platform=linux npm_config_target=8.10.0 npm install --save sharp
```
