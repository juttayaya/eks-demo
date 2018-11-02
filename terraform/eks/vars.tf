variable "eks-cluster-name" {
  default = "javajirawat-eks-demo"
  type    = "string"
}

variable "eks-cluster-cidr-prefix" {
  default = "172.17"
  type    = "string"
}
