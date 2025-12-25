provider "aws" {
  region = "us-east-1"
}

# Get current account ID
data "aws_caller_identity" "current" {}

# Create a mock/fake cluster role ARN for testing
# Since we're not actually creating resources, we just need a valid ARN format
locals {
  mock_cluster_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/mock-eks-cluster-role"
}

module "test_kms" {
  source = "../"

  cluster_name            = "test-cluster-day3"
  aws_account_id          = data.aws_caller_identity.current.account_id
  cluster_role_arn        = local.mock_cluster_role_arn
  deletion_window_in_days = 7
  enable_key_rotation     = true
  multi_region            = false

  tags = {
    Environment = "test"
    Purpose     = "module-testing"
    Day         = "3"
  }
}

output "kms_key_arn" {
  description = "KMS Key ARN from module"
  value       = module.test_kms.kms_key_arn
}

output "kms_key_id" {
  description = "KMS Key ID from module"
  value       = module.test_kms.kms_key_id
}

output "kms_alias_name" {
  description = "KMS Alias name"
  value       = module.test_kms.kms_alias_name
}