terraform {
  backend "s3" {
    bucket = "tfstate-s3-eks"
    region = "us-east-1"
    key = "eks-demo/tf-infra/terraform.tfstate"
    encrypt = true
    dynamodb_table = "tflock-eks"
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
    project_name  = "JavaJirawat EKS demo"
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
      Org = "${local.project_name}"
    }
}      

resource "aws_dynamodb_table" "tflock-eks" {
  name = "tflock-eks"
  hash_key = "LockID"
  read_capacity = 5
  write_capacity = 5
 
  attribute {
    name = "LockID"
    type = "S"
  }
 
  tags {
    Name = "Terraform DynamoDB Lock Table for EKS demo"
    Org = "${local.project_name}"
  }
}
