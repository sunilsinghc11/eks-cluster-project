# ============================================================
# Inline IAM policy attached to the IAM user
#
# NOTE: Your current principal did not have permission to call iam:CreatePolicy
# (Create managed policies). To avoid requiring iam:CreatePolicy, we attach the
# permissions as an inline policy on the IAM user using aws_iam_user_policy.
# This requires iam:PutUserPolicy permission instead of iam:CreatePolicy.
# If your principal cannot put inline policies either, ask an administrator to
# create the managed policy and then import it into state (see README or
# instructions printed after apply).
# ============================================================

/*
This configuration previously created an IAM managed policy or attached an
inline policy to the IAM user. Creating or modifying IAM policies requires
privileged IAM actions (iam:CreatePolicy or iam:PutUserPolicy /
iam:AttachUserPolicy). Your current principal does not have those
permissions, so Terraform was failing with AccessDenied.

To avoid requiring elevated IAM permissions from the principal running
Terraform, we no longer attempt to create or attach IAM policies here. Instead
we output the policy document so an administrator can create and attach the
managed policy manually (or grant permissions to the deployer to allow
Terraform to do so).

Recommended workflow for admins (example):

1. Save the value of the output `eks_provisioning_policy_json` to a file, e.g.
   `eks_provisioning_policy.json`.
2. As an administrator, create the managed policy:
   aws iam create-policy --policy-name EKSProvisioningPermissions \
     --policy-document file://eks_provisioning_policy.json
3. (Optional) Import the managed policy into Terraform state:
   terraform import aws_iam_policy.eks_terraform_user_policy \
     arn:aws:iam::<ACCOUNT_ID>:policy/EKSProvisioningPermissions

Or attach the policy directly to the user using the admin account.
*/

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

# If you can provide an elevated AWS profile via variable `admin_aws_profile`,
# Terraform can create the managed policy and attach it using the aliased
# `aws.admin` provider. Set `admin_aws_profile` to the name of a profile in
# your AWS credentials file that has iam:CreatePolicy and iam:AttachUserPolicy
# permissions. Example: `export TF_VAR_admin_aws_profile=admin` or pass
# `-var='admin_aws_profile=admin'` to terraform commands.
# Policy creation removed - using existing roles instead
