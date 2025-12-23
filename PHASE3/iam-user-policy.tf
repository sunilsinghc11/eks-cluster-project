# NOTE: This file provides a policy template that an admin can create/attach if
# your deploying user lacks iam:CreatePolicy/iam:AttachUserPolicy permissions.
# The managed policy creation is intentionally not automated by default in PHASE2.

locals {
  eks_provisioning_policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "EKSAndIAMPermissions"
        Effect = "Allow"
        Action = [
          "eks:*",
          "iam:CreateRole",
          "iam:TagRole",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PassRole",
          "iam:ListInstanceProfilesForRole",
          "iam:CreateInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ]
        Resource = "*"
      }
    ]
  }
}

output "eks_provisioning_policy_json" {
  description = "Policy JSON for EKS provisioning. Save this to a file and have an admin create a managed policy or attach it as appropriate."
  value       = jsonencode(local.eks_provisioning_policy)
  sensitive   = false
}
