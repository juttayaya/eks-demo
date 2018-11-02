terraform {
  backend "s3" {
    bucket = "tfstate-s3-eks"
    region = "us-east-1"
    key = "eks-demo/eks/terraform.tfstate"
    encrypt = true
    dynamodb_table = "tflock-eks"
  }
}
