output "eks-demo-ecr-name" {
    value = "${aws_ecr_repository.eks-demo-ecr.name}"
}

output "eks-demo-ecr-url" {
    value = "${aws_ecr_repository.eks-demo-ecr.repository_url}"
}
