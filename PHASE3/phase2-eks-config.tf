data "aws_eks_cluster" "main" {
  name       = aws_eks_cluster.main.name
  depends_on = [aws_eks_cluster.main]
}

data "aws_eks_cluster_auth" "main" {
  name       = aws_eks_cluster.main.name
  depends_on = [aws_eks_cluster.main]
}

data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "eks_logs" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_group_retention_days

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "${var.cluster_name}-logs"
    Environment = "development"
  }
}
// `aws-auth` ConfigMap intentionally not managed by Terraform in this phase.

output "cloudwatch_log_group_name" {
  value       = aws_cloudwatch_log_group.eks_logs.name
  description = "EKS CloudWatch log group name"
}

output "eks_kubeconfig" {
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
  description = "Command to configure kubectl"
}

output "aws_auth_configmap_status" {
  value       = "aws-auth ConfigMap grants '${var.iam_user_name}' admin access to the cluster"
  description = "Kubernetes ConfigMap for IAM user/role mappings"
}
