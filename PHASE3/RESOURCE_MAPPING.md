# PHASE3 to Modules Resource Mapping

## Current PHASE3 Resources

(Fill this in after running the grep commands above)

Example:
- Line 45: resource "aws_kms_key" "eks_secrets" { }
- Line 67: resource "aws_kms_alias" "eks_secrets_alias" { }
- Line 89: resource "aws_cloudwatch_log_group" "eks_logs" { }
- Line 102: resource "aws_iam_policy" "user_access" { }

### Found in main.tf (or other files):
> grep -n "^resource " *.tf
phase1-basic.tf:60:resource "aws_vpc" "main" {
phase1-basic.tf:68:resource "aws_internet_gateway" "main" {
phase1-basic.tf:78:resource "aws_subnet" "public" {
phase1-basic.tf:92:resource "aws_subnet" "private" {
phase1-basic.tf:109:resource "aws_eip" "nat" {
phase1-basic.tf:118:resource "aws_nat_gateway" "main" {
phase1-basic.tf:132:resource "aws_route_table" "public" {
phase1-basic.tf:143:resource "aws_route_table" "private" {
phase1-basic.tf:154:resource "aws_route_table_association" "public" {
phase1-basic.tf:160:resource "aws_route_table_association" "private" {
phase1-basic.tf:171:resource "aws_kms_key" "eks" {
phase1-basic.tf:216:resource "aws_kms_alias" "eks_alias" {
phase1-basic.tf:230:resource "aws_iam_role" "cluster" {
phase1-basic.tf:245:resource "aws_iam_role_policy_attachment" "cluster_policy" {
phase1-basic.tf:250:resource "aws_iam_role" "node" {
phase1-basic.tf:265:resource "aws_iam_role_policy_attachment" "node_policy" {
phase1-basic.tf:270:resource "aws_iam_role_policy_attachment" "node_cni_policy" {
phase1-basic.tf:275:resource "aws_iam_role_policy_attachment" "node_registry_policy" {
phase1-basic.tf:284:resource "aws_eks_cluster" "main" {
phase1-basic.tf:323:resource "aws_eks_node_group" "main" {
phase2-eks-config.tf:13:resource "aws_cloudwatch_log_group" "eks_logs" {

> grep -n "aws_kms" *.tf
phase1-basic.tf:171:resource "aws_kms_key" "eks" {
phase1-basic.tf:216:resource "aws_kms_alias" "eks_alias" {
phase1-basic.tf:219:  target_key_id = aws_kms_key.eks[0].key_id
phase1-basic.tf:223:  kms_arn = var.kms_key_arn != "" ? var.kms_key_arn : (var.create_kms_key ? aws_kms_key.eks[0].arn : "")

> grep -n "aws_cloudwatch" *.tf
phase1-basic.tf:313:    aws_cloudwatch_log_group.eks_logs
phase2-eks-config.tf:13:resource "aws_cloudwatch_log_group" "eks_logs" {
phase2-eks-config.tf:29:  value       = aws_cloudwatch_log_group.eks_logs.name

> grep -n "aws_iam" *.tf
phase1-basic.tf:195:          AWS = aws_iam_role.cluster.arn
phase1-basic.tf:230:resource "aws_iam_role" "cluster" {
phase1-basic.tf:245:resource "aws_iam_role_policy_attachment" "cluster_policy" {
phase1-basic.tf:247:  role       = aws_iam_role.cluster.name
phase1-basic.tf:250:resource "aws_iam_role" "node" {
phase1-basic.tf:265:resource "aws_iam_role_policy_attachment" "node_policy" {
phase1-basic.tf:267:  role       = aws_iam_role.node.name
phase1-basic.tf:270:resource "aws_iam_role_policy_attachment" "node_cni_policy" {
phase1-basic.tf:272:  role       = aws_iam_role.node.name
phase1-basic.tf:275:resource "aws_iam_role_policy_attachment" "node_registry_policy" {
phase1-basic.tf:277:  role       = aws_iam_role.node.name
phase1-basic.tf:286:  role_arn = aws_iam_role.cluster.arn
phase1-basic.tf:326:  node_role_arn   = aws_iam_role.node.arn

## Mapping to Modules

### To: modules/kms-encryption/
- aws_kms_key.eks_secrets
- aws_kms_alias.eks_secrets_alias

### To: modules/eks-logging/
- aws_cloudwatch_log_group.eks_logs

### To: modules/iam-access/
- aws_iam_policy.user_access
- aws_iam_user_policy_attachment.*

### To: modules/k8s-manifests/
- kubernetes_namespace.*
- kubernetes_deployment.*
- kubernetes_service.*

## Resources Staying in PHASE3/main.tf
- Provider configurations
- Data sources
- Module calls (after migration)

