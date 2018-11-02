resource "aws_vpc" "eks-demo-vpc" {
  cidr_block = "${var.eks-cluster-cidr-prefix}.0.0/16"

  tags = "${
    map(
     "Name", "eks-demo-vpc",
     "kubernetes.io/cluster/${var.eks-cluster-name}", "shared",
     "EKS-Cluster", "${var.eks-cluster-name}"
    )
  }"
}

resource "aws_subnet" "eks-demo-subnet" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "${var.eks-cluster-cidr-prefix}.${count.index}.0/24"
  vpc_id            = "${aws_vpc.eks-demo-vpc.id}"

  tags = "${
    map(
     "Name", "eks-demo-subnet",
     "EKS-Cluster", "${var.eks-cluster-name}",
     "kubernetes.io/cluster/${var.eks-cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "eks-demo-gateway" {
  vpc_id = "${aws_vpc.eks-demo-vpc.id}"

  tags = "${
    map(
     "Name", "eks-demo-gateway",
     "kubernetes.io/cluster/${var.eks-cluster-name}", "shared",
     "EKS-Cluster", "${var.eks-cluster-name}"
    )
  }"
}

resource "aws_route_table" "eks-demo-routetable" {
  vpc_id = "${aws_vpc.eks-demo-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.eks-demo-gateway.id}"
  }

  tags = "${
    map(
     "Name", "eks-demo-routetable",
     "kubernetes.io/cluster/${var.eks-cluster-name}", "shared",
     "EKS-Cluster", "${var.eks-cluster-name}"
    )
  }"
}

resource "aws_route_table_association" "eks-demo-routetable-assoc" {
  count = 2

  subnet_id      = "${aws_subnet.eks-demo-subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.eks-demo-routetable.id}"
}
