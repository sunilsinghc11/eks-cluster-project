

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

# Admin AWS provider (optional)
# If you set variable `admin_aws_profile`, Terraform will use that AWS CLI profile
# for IAM operations that require elevated permissions (create managed policies, attach policies, etc.).
provider "aws" {
  alias   = "admin"
  region  = var.aws_region
  profile = var.admin_aws_profile
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "development"
      ManagedBy   = "Terraform"
      Project     = var.cluster_name
      Phase       = "2-secure"
    }
  }
}

# Kubernetes provider configured from EKS data sources. This allows Terraform to
# manage Kubernetes resources (aws-auth ConfigMap) using the cluster endpoint
# and temporary token provided by the EKS data sources. We disable loading the
# local kubeconfig file so Terraform uses these values directly.
provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  token                  = data.aws_eks_cluster_auth.main.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
}

# ============================================================
# DATA SOURCES
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================
# VPC
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.cluster_name}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.cluster_name}-igw" }
}

# ============================================================
# SUBNETS
# ============================================================

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.cluster_name}-public-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                        = "${var.cluster_name}-private-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# ============================================================
# NAT GATEWAY
# ============================================================

resource "aws_eip" "nat" {
  count  = var.nat_gateway_count
  domain = "vpc"

  tags = { Name = "${var.cluster_name}-nat-eip-${count.index + 1}" }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = var.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = { Name = "${var.cluster_name}-nat-${count.index + 1}" }

  depends_on = [aws_internet_gateway.main]
}

# ============================================================
# ROUTE TABLES
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.cluster_name}-public-rt" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = { Name = "${var.cluster_name}-private-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ============================================================
# KMS (optional)
# ============================================================

# Create a customer-managed KMS key for EKS secrets encryption if requested.
resource "aws_kms_key" "eks" {
  count                    = var.create_kms_key ? 1 : 0
  description             = "KMS key for EKS secrets encryption - ${var.cluster_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true  # Enable automatic key rotation
  multi_region           = false  # Set to true if you need multi-region support
  
  # More restrictive key policy
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EKS to use the key"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.cluster.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-kms"
    Environment = "production"
    Purpose     = "eks-encryption"
  }
}

resource "aws_kms_alias" "eks_alias" {
  count = var.create_kms_key ? 1 : 0
  name  = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks[0].key_id
}

locals {
  kms_arn = var.kms_key_arn != "" ? var.kms_key_arn : (var.create_kms_key ? aws_kms_key.eks[0].arn : "")
}

# ============================================================
# IAM ROLES (managed)
# ============================================================

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "eks.amazonaws.com" } }]
  })

  tags = { Name = "${var.cluster_name}-cluster-role" }

  lifecycle {
    prevent_destroy = false  # Temporarily disabled for cleanup
  }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })

  tags = { Name = "${var.cluster_name}-node-role" }

  lifecycle {
    prevent_destroy = false  # Temporarily disabled for cleanup
  }
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# ============================================================
# EKS CLUSTER
# ============================================================

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  # Enable cluster control plane logging types configured via variables
  enabled_cluster_log_types = var.enabled_cluster_log_types

  vpc_config {
    subnet_ids = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)

    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access

    // Only set public cidrs when provided
    public_access_cidrs = var.endpoint_public_access ? var.public_access_cidrs : []
  }

  dynamic "encryption_config" {
    for_each = local.kms_arn != "" ? [local.kms_arn] : []
    content {
      resources = ["secrets"]
      provider {
        key_arn = encryption_config.value
      }
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.eks_logs
  ]

  tags = { Name = var.cluster_name }
}

# ============================================================
# EKS NODE GROUP
# ============================================================

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = var.instance_types

  tags = { Name = "${var.cluster_name}-node-group" }

  # No dependencies needed as roles are pre-created

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
