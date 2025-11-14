variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "my-eks-cluster"
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
  default = ["10.0.100.0/24","10.0.101.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24","10.0.1.0/24"]
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
  default = 14
}

variable "admin_aws_profile" {
  description = "(Optional) AWS CLI profile name that has permissions to manage IAM resources (used by Terraform for IAM operations). If empty, the default credential chain is used."
  type        = string
  default     = ""
}
