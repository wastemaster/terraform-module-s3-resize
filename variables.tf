variable "project_name" {
  description = "Project name"
}

variable "environment" {
  description = "The name of the environment"
}

variable "aws_region" {
  description = "Region where the resources will be created"
}

################################################################################

variable "bucket_name" {
  description = "Name of the bucket. Full bucket name will consist of project_name-environment-bucket_name"
}

variable "should_create_user" {
  default     = true
  description = "Specify whether the module should create new user for the S3 bucket."
}

variable "tags" {
  description = "Tags to apply to each taggable resource"
  type        = map
  default     = {}
}
