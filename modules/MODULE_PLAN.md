# PHASE3 Modularization Plan

## Module Organization Strategy

### Module 1: kms-encryption
**Purpose:** Manage KMS keys for EKS secrets encryption

**Resources to Extract from PHASE3:**
- [ ] aws_kms_key
- [ ] aws_kms_alias
- [ ] Related IAM policies (if any)

**Inputs Needed:**
- cluster_name
- deletion_window_in_days
- tags

**Outputs Provided:**
- kms_key_arn
- kms_key_id

**Priority:** HIGH (needed by other modules)

---

### Module 2: eks-logging
**Purpose:** Manage CloudWatch log groups for EKS

**Resources to Extract from PHASE3:**
- [ ] aws_cloudwatch_log_group

**Inputs Needed:**
- cluster_name
- log_retention_days
- kms_key_id (from kms-encryption module)
- tags

**Outputs Provided:**
- log_group_name
- log_group_arn

**Priority:** HIGH

---

### Module 3: iam-access
**Purpose:** Manage IAM policies for user access to EKS

**Resources to Extract from PHASE3:**
- [ ] aws_iam_policy
- [ ] aws_iam_user_policy_attachment
- [ ] aws_iam_role_policy_attachment (if any)

**Inputs Needed:**
- cluster_name
- cluster_arn
- iam_users (list)
- iam_roles (list)
- tags

**Outputs Provided:**
- policy_arn
- policy_name

**Priority:** MEDIUM

---

### Module 4: k8s-manifests
**Purpose:** Manage Kubernetes resources (namespaces, deployments, etc.)

**Resources to Extract from PHASE3:**
- [ ] kubernetes_namespace (with PSA labels)
- [ ] kubernetes_deployment (sample apps)
- [ ] kubernetes_service
- [ ] kubernetes_network_policy (if defined in Terraform)

**Inputs Needed:**
- namespaces (map with PSA config)
- deploy_sample_app (boolean)
- app configuration variables

**Outputs Provided:**
- namespace_names
- service_names

**Priority:** MEDIUM

---

## Migration Order (Days 3-7)

Day 3: kms-encryption (FIRST - others depend on it)
Day 4: Connect kms-encryption to PHASE3
Day 5: eks-logging (uses KMS output)
Day 6: iam-access (independent)
Day 7: k8s-manifests (independent)

## Success Criteria

- [ ] All modules have complete files (main, variables, outputs, versions)
- [ ] Each module is self-contained
- [ ] Modules have clear inputs/outputs
- [ ] Documentation exists for each module
- [ ] PHASE3 uses all modules successfully
- [ ] No duplicate resources between modules

