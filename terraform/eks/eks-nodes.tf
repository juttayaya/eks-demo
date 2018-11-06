# EKS Worker Nodes

resource "aws_iam_role" "eks-demo-node-iam-role" {
  name = "eks-demo-node-iam-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-demo-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.eks-demo-node-iam-role.name}"
}

resource "aws_iam_role_policy_attachment" "eks-demo-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.eks-demo-node-iam-role.name}"
}

resource "aws_iam_role_policy_attachment" "eks-demo-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.eks-demo-node-iam-role.name}"
}

resource "aws_iam_instance_profile" "eks-demo-node-instance-profile" {
  name = "eks-demo-instance-profile"
  role = "${aws_iam_role.eks-demo-node-iam-role.name}"
}

resource "aws_security_group" "eks-demo-node-security-group" {
  name        = "eks-demo-node-security-group"
  description = "EKS Demo Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.eks-demo-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "eks-demo-node-security-group",
     "kubernetes.io/cluster/${var.eks-cluster-name}", "owned",
     "EKS-Cluster", "${var.eks-cluster-name}"
    )
  }"
}

resource "aws_security_group_rule" "eks-demo-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.eks-demo-node-security-group.id}"
  source_security_group_id = "${aws_security_group.eks-demo-node-security-group.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-demo-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-demo-node-security-group.id}"
  source_security_group_id = "${aws_security_group.eks-demo-security-group.id}"
  to_port                  = 65535
  type                     = "ingress"
}

data "aws_ami" "eks-node-worker-ami" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  eks-demo-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks-demo-cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks-demo-cluster.certificate_authority.0.data}' '${var.eks-cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "eks-demo-launch-config" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.eks-demo-node-instance-profile.name}"
  image_id                    = "${data.aws_ami.eks-node-worker-ami.id}"
  instance_type               = "t2.large"
  name_prefix                 = "eks-demo"
  security_groups             = ["${aws_security_group.eks-demo-node-security-group.id}"]
  user_data_base64            = "${base64encode(local.eks-demo-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks-demo-asg" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.eks-demo-launch-config.id}"
  max_size             = 3
  min_size             = 1
  name                 = "eks-demo-asg"
  vpc_zone_identifier  = ["${aws_subnet.eks-demo-subnet.*.id}"]

  tag {
    key                 = "Name"
    value               = "eks-demo-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "EKS-Cluster"
    value               = "${var.eks-cluster-name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.eks-cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
