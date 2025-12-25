# KMS Encryption Module

## Purpose
Creates and manages a KMS key for EKS secrets encryption with automatic rotation.

## Features
- ✅ Automatic key rotation
- ✅ Configurable deletion window (7-30 days)
- ✅ Custom KMS policy for EKS cluster access
- ✅ KMS alias for easy reference
- ✅ Multi-region support option
- ✅ Tagging support

## Usage
```hcl
data "aws_caller_identity" "current" {}

data "aws_iam_role" "cluster" {
  name = "my-eks-cluster-role"
}

module "kms_encryption" {
  source = "../modules/kms-encryption"

  cluster_name            = "my-eks-cluster"
  aws_account_id          = data.aws_caller_identity.current.account_id
  cluster_role_arn        = data.aws_iam_role.cluster.arn
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region            = false

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | EKS cluster name | string | - | yes |
| aws_account_id | AWS Account ID | string | - | yes |
| cluster_role_arn | EKS cluster IAM role ARN | string | - | yes |
| deletion_window_in_days | Days before key deletion | number | 30 | no |
| enable_key_rotation | Enable automatic rotation | bool | true | no |
| multi_region | Enable multi-region support | bool | false | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| kms_key_id | The ID of the KMS key |
| kms_key_arn | The ARN of the KMS key |
| kms_alias_name | The name of the KMS alias |
| kms_alias_arn | The ARN of the KMS alias |

## Example Output Usage

Use the KMS key ARN in your EKS cluster encryption configuration:
```hcl
resource "aws_eks_cluster" "main" {
  # ... other configuration ...

  encryption_config {
    provider {
      key_arn = module.kms_encryption.kms_key_arn
    }
    resources = ["secrets"]
  }
}
```

## KMS Policy

The module creates a KMS key policy that allows:

1. **Root account** - Full access to manage the key
2. **EKS cluster role** - Encrypt/decrypt operations for secrets

## Security Features

- **Automatic key rotation**: Enabled by default (yearly rotation)
- **Deletion protection**: 7-30 day deletion window
- **Least privilege**: EKS role only gets encrypt/decrypt permissions
- **Audit trail**: All key usage logged to CloudTrail

## Notes

- The KMS alias makes it easier to reference the key (human-readable)
- Key rotation happens automatically without service interruption
- Deletion window protects against accidental key deletion
