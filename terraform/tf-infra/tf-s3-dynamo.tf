provider "aws" {
  region = "us-east-1"
}
 
resource "aws_s3_bucket" "tfstate-s3-eks" {
    bucket = "tfstate-s3-eks"
    acl = "private"
 
    versioning {
      enabled = true
    }
 
    lifecycle {
      prevent_destroy = true
    }
 
    tags {
      Name = "Terraform tfstate S3 for EKS demo"
      Org = "JavaJirawat EKS demo"
    }
}      
