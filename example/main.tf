################################################
###### Providers
################################################

provider "aws" {
  region = "ap-southeast-1"
}


################################################
###### S3 resize
################################################


module "main-bucket" {
  source = "git@github.com:usertech/terraform-module-s3-resize.git"

  aws_region   = "ap-southeast-1"
  bucket_name  = "app-bucket"
  environment  = "test"
  project_name = "s3resize"
  tags         = {}
}
