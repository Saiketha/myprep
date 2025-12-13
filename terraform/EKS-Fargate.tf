data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks.name
}

resource "aws_eks_cluster" "eks" {
  name     = "example-eks-fargate"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [element(values(aws_subnet.private),0).id, element(values(aws_subnet.private),1).id]
    endpoint_public_access = true
  }

  # minimal: skip cluster logging, addons, etc.
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Principal = { Service = "eks.amazonaws.com" }, Action = "sts:AssumeRole" }
    ]
  })
}
# Attach required policies (example using AWS managed policies)
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Fargate profile
resource "aws_eks_fargate_profile" "fp" {
  cluster_name = aws_eks_cluster.eks.name
  fargate_profile_name = "example-fp"
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn
  subnet_ids = [element(values(aws_subnet.private),0).id]

  selector {
    namespace = "default"
  }
}

resource "aws_iam_role" "eks_fargate_pod_execution_role" {
  name = "eks-fargate-pod-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "eks-fargate-pods.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}
resource "aws_iam_role_policy_attachment" "eks_fargate_AmazonEKSFargatePodExecutionRolePolicy" {
  role       = aws_iam_role.eks_fargate_pod_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}
