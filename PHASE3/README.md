PHASE2 - EKS security-hardened configuration

This folder is a security-focused copy of the PHASE1 configuration. It includes conservative defaults that follow a subset of the AWS EKS security best practices (https://docs.aws.amazon.com/eks/latest/best-practices/security.html).

What changed (high level):
- EKS API endpoint is private by default (`endpoint_private_access = true`, `endpoint_public_access = false`).
- Optional KMS key creation for secrets encryption (controlled by `create_kms_key` and `kms_key_arn`).
- IAM roles are managed by Terraform but protected from accidental deletion by default via `prevent_destroy_iam_roles = true`.
- Control-plane logging is enabled by default via `enabled_cluster_log_types`.
- Example Kubernetes manifests for Pod Security and NetworkPolicy are provided in `manifests/` (apply manually with kubectl).

How to use (quick):

1. Review variables in `variables.tf` and update defaults as required.

2. If you want Terraform to create a KMS key for secrets encryption, set `create_kms_key = true` (requires KMS permissions). Alternatively create a CMK in console and set `kms_key_arn`.

3. Initialize and plan (in PHASE2):

```bash
cd PHASE2
terraform init
terraform plan -out plan.tfplan
```

4. Apply (creates infra):

```bash
terraform apply "plan.tfplan"
# or
terraform apply -auto-approve
```

Notes & admin steps:
- If your deploying user lacks KMS or IAM privileges, either run those steps with an admin profile (set `TF_VAR_admin_aws_profile`) or have an admin create the KMS key and/or attach any required managed policies.
- `prevent_destroy_iam_roles` defaults to true to avoid accidental deletion of roles used by other systems. Remove or set to false intentionally when you want to delete roles.

Security artifacts in this folder:
- `manifests/pod-security.yaml` - legacy PSP example (deprecated, kept for reference)
- `manifests/psa-labels.yaml` - Pod Security Admission namespace configurations in audit mode
- `manifests/psa-test-pods.yaml` - Test pods for validating PSA configurations
- `manifests/network-policy-example.yaml` - example NetworkPolicy to isolate namespaces/pods

Pod Security Strategy:
1. PSP to PSA Migration
   - We are migrating from Pod Security Policy (PSP, deprecated) to Pod Security Admission (PSA)
   - PSA uses simple namespace labels instead of complex RBAC bindings
   - Implementation follows a gradual approach:
     a. Start with audit/warn modes (see psa-labels.yaml)
     b. Monitor violations using test pods (see psa-test-pods.yaml)
     c. Fix non-compliant workloads
     d. Enable enforcement mode per namespace

2. Next Steps for Pod Security:
   ```bash
   # Apply namespace labels in audit mode
   kubectl apply -f manifests/psa-labels.yaml
   
   # Run test pods and check results
   kubectl apply -f manifests/psa-test-pods.yaml
   kubectl get events -n staging
   
   # When ready to enforce (after fixing violations):
   kubectl label ns staging pod-security.kubernetes.io/enforce=restricted
   kubectl label ns production pod-security.kubernetes.io/enforce=restricted
   ```

If you want, I can:
- Run `terraform init && terraform plan` here and report the plan.
- Toggle any of the conservative defaults (e.g., enable KMS creation by default).
- Add IAM OIDC provider and sample IRSA role templates (requires additional steps).
