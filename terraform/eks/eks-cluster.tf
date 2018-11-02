resource "aws_iam_role" "eks-demo-iam-role" {
  name = "eks-demo-iam-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-demo-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks-demo-iam-role.name}"
}

resource "aws_iam_role_policy_attachment" "eks-demo-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks-demo-iam-role.name}"
}

resource "aws_security_group" "eks-demo-security-group" {
  name        = "eks-demo-security-group"
  description = "EKS Demo worker nodes Cluster communication"
  vpc_id      = "${aws_vpc.eks-demo-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "eks-demo-security-group",
     "EKS-Cluster", "${var.eks-cluster-name}"
    )
  }"
}

resource "aws_security_group_rule" "eks-demo-ingress-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-demo-security-group.id}"
  source_security_group_id = "${aws_security_group.eks-demo-node-security-group.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-demo-cluster-ingress-kubectl-https" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.eks-demo-security-group.id}"
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "eks-demo-cluster" {
  name     = "${var.eks-cluster-name}"
  role_arn = "${aws_iam_role.eks-demo-iam-role.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.eks-demo-security-group.id}"]
    subnet_ids         = ["${aws_subnet.eks-demo-subnet.*.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.eks-demo-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.eks-demo-AmazonEKSServicePolicy",
  ]
}

