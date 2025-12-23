variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "prod-secure-eks-cluster"
}

variable "cluster_version" {
  type    = string
  default = "1.31"
}

variable "enabled_cluster_log_types" {
  type    = list(string)
  default = ["api","audit","authenticator","controllerManager","scheduler"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.100.0/24","10.0.101.0/24","10.0.102.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24","10.0.1.0/24","10.0.2.0/24"]
}

variable "nat_gateway_count" {
  type    = number
  default = 1
}

variable "iam_user_name" {
  type    = string
  default = "sunil"
}

variable "cloudwatch_log_group_retention_days" {
  type    = number
  default = 90
}

variable "admin_aws_profile" {
  description = "(Optional) AWS CLI profile name that has permissions to manage IAM resources (used by Terraform for IAM operations). If empty, the default credential chain is used."
  type        = string
  default     = ""
}

# Security-related variables
variable "endpoint_private_access" {
  description = "Whether EKS API endpoint is private (accessible from within VPC)."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether EKS API endpoint is public. Set false to restrict public access."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "If public access is enabled, restrict CIDRs allowed to access the control plane API."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_kms_key" {
  description = "If true, Terraform will create a customer-managed KMS key for EKS secrets encryption. Otherwise supply `kms_key_arn`."
  type        = bool
  default     = true  # Enabled KMS key creation by default
}

variable "kms_key_arn" {
  description = "Optional existing KMS key ARN to use for secrets encryption. If empty and create_kms_key=true, Terraform creates one."
  type        = string
  default     = ""
}

variable "prevent_destroy_iam_roles" {
  description = "Protect IAM roles from accidental destroy. Set false only when you intentionally want to remove roles."
  type        = bool
  default     = true
}

# Node group sizing
variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}
