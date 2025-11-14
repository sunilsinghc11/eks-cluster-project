# EKS Cluster with Security Hardening

Production-ready Amazon EKS cluster with comprehensive security controls including Pod Security Admission (PSA), network policies, and KMS encryption.

## 🏗️ Architecture Overview

- **EKS Version**: 1.31.13
- **Region**: us-east-1
- **VPC CIDR**: 10.0.0.0/16
- **Service CIDR**: 172.20.0.0/16
- **Worker Nodes**: 2 nodes in private subnets
- **CNI**: AWS VPC CNI (native VPC networking)

## 📁 Project Structure

```
eks-cluster-project/
├── PHASE1/                    # Initial cluster setup
│   ├── phase1-basic.tf       # VPC, EKS cluster, node groups
│   ├── phase2-eks-config.tf  # CloudWatch logs, outputs
│   ├── iam-user-policy.tf    # IAM user access configuration
│   └── variables.tf          # Configuration variables
│
├── PHASE2/                    # Security hardening
│   ├── manifests/
│   │   ├── psa-labels.yaml           # Pod Security Admission namespaces
│   │   ├── sample-app-deployment.yaml # Secure nginx deployment + service
│   │   ├── production-netpol.yaml    # Network policy (ingress/egress rules)
│   │   └── test-clients.yaml         # Network policy test pods
│   └── [Terraform files]
```

## 🚀 Deployment Steps

### 1. Infrastructure Setup

```bash
cd PHASE2

# Initialize Terraform
terraform init -backend-config=backend.tfvars

# Plan the deployment
terraform plan -var-file=terraform.tfvars

# Apply the configuration
terraform apply -var-file=terraform.tfvars
```

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name prod-secure-eks-cluster

# Verify cluster access
kubectl get nodes
```

### 3. Apply Security Configurations

```bash
cd manifests

# Create namespaces with PSA enforcement
kubectl apply -f psa-labels.yaml

# Deploy secure nginx application
kubectl apply -f sample-app-deployment.yaml

# Apply network policies
kubectl apply -f production-netpol.yaml

# Deploy test clients (for validation)
kubectl apply -f test-clients.yaml
```

## 🔒 Security Features

### Pod Security Admission (PSA)

**Enforced Profile**: `restricted` (highest security level)

PSA blocks pods that violate security policies:
- ❌ Privileged containers
- ❌ Running as root (UID 0)
- ❌ Host namespace access (hostNetwork, hostPID, hostIPC, hostPath)
- ❌ Privilege escalation
- ❌ Insecure capabilities
- ✅ Requires seccomp profile
- ✅ Enforces read-only root filesystem
- ✅ Drops all capabilities

**Namespaces with PSA**:
```yaml
staging:
  enforce: restricted
  audit: restricted
  warn: restricted

production:
  enforce: restricted
  audit: restricted
  warn: restricted
```

### Secure Application Configuration

The nginx deployment implements security best practices:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
  capabilities:
    drop:
      - ALL

containerSecurityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
  capabilities:
    drop:
      - ALL
```

**Resource Limits**:
- CPU: 200m request, 500m limit
- Memory: 128Mi request, 256Mi limit

### Network Policies

**Ingress Rules**:
- Only allow traffic from pods labeled `access: frontend`
- Restrict to port 8080 (application port)

**Egress Rules**:
- DNS queries to kube-system namespace (port 53/UDP)
- HTTPS to external services (port 443/TCP)

**Note**: AWS VPC CNI does not enforce NetworkPolicies by default. For production enforcement, consider:
- AWS VPC CNI with Network Policy support enabled
- Calico CNI plugin
- Cilium CNI plugin

### KMS Encryption

- **Secrets Encryption**: Enabled with customer-managed KMS key
- **Key Rotation**: Automatic rotation enabled
- **Deletion Window**: 30 days

### CloudWatch Logging

Enabled log types:
- API server logs
- Audit logs
- Authenticator logs
- Controller manager logs
- Scheduler logs

## 🧪 Security Validation

### 1. Verify PSA Enforcement

Test that PSA blocks non-compliant pods:

```bash
# Try to create privileged pod (should fail)
kubectl run test-privileged --image=nginx --privileged=true -n production

# Try to create pod with hostPath (should fail)
kubectl run test-hostpath --image=nginx \
  --overrides='{"spec":{"volumes":[{"name":"host","hostPath":{"path":"/"}}]}}' \
  -n production
```

Expected: `Error from server (Forbidden): pods "test-*" is forbidden: violates PodSecurity`

### 2. Verify Application Security

```bash
# Check pod is running as non-root
kubectl exec -n production deploy/secure-nginx-deployment -- id

# Expected output:
# uid=1000 gid=1000 groups=1000

# Verify read-only filesystem
kubectl exec -n production deploy/secure-nginx-deployment -- touch /test
# Expected: Read-only file system error
```

### 3. Test Network Policy (Conceptual)

```bash
# Test from allowed client
kubectl exec -n production test-client -- curl -s http://secure-nginx-service

# Test from blocked client
kubectl exec -n production blocked-client -- curl -s http://secure-nginx-service
```

**Note**: Both will succeed due to AWS VPC CNI limitation. NetworkPolicy is defined but not enforced.

## 🌐 Networking Architecture

### Service Discovery

```
Client Request Flow:
1. DNS Query: secure-nginx-service.production.svc.cluster.local
2. CoreDNS resolves to: 172.20.45.119 (ClusterIP from Service CIDR)
3. kube-proxy iptables NAT: 172.20.45.119:80 → Pod IPs (10.0.x.x:8080)
4. Traffic load balanced across pods:
   - 10.0.0.177:8080 (50%)
   - 10.0.2.28:8080 (50%)
```

### IP Address Ranges

| Component | CIDR/IP | Purpose |
|-----------|---------|---------|
| VPC | 10.0.0.0/16 | Real network IPs (nodes, pods) |
| Service CIDR | 172.20.0.0/16 | Virtual IPs for Services (ClusterIP) |
| Public Subnets | 10.0.1.0/24, 10.0.3.0/24 | Internet-facing resources |
| Private Subnets | 10.0.0.0/24, 10.0.2.0/24 | Worker nodes, pods |
| CoreDNS | 172.20.0.10 | Kubernetes DNS service |

## 🔍 Monitoring & Troubleshooting

### Check Cluster Health

```bash
# Node status
kubectl get nodes

# System pods
kubectl get pods -n kube-system

# Application pods
kubectl get pods -n production

# Service endpoints
kubectl get endpoints -n production
```

### View CloudWatch Logs

```bash
# List log streams
aws logs describe-log-streams \
  --log-group-name /aws/eks/prod-secure-eks-cluster/cluster \
  --region us-east-1

# View audit logs
aws logs filter-log-events \
  --log-group-name /aws/eks/prod-secure-eks-cluster/cluster \
  --log-stream-name-prefix kube-apiserver-audit
```

### Debug PSA Issues

```bash
# Check namespace PSA labels
kubectl get ns production -o yaml | grep pod-security

# View PSA warnings
kubectl describe pod <pod-name> -n production
```

### Debug Networking

```bash
# Check service ClusterIP
kubectl get svc -n production

# View service endpoints
kubectl describe svc secure-nginx-service -n production

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup secure-nginx-service.production.svc.cluster.local

# View iptables rules (on node)
sudo iptables -t nat -L KUBE-SERVICES | grep secure-nginx
```

## 🧹 Cleanup

```bash
# Delete Kubernetes resources
kubectl delete -f PHASE2/manifests/

# Destroy infrastructure
cd PHASE2
terraform destroy -var-file=terraform.tfvars
```

## 📚 Key Learnings

### Pod Security Admission (PSA)
- PSA is built into the Kubernetes API server (no addon required)
- Enforced at namespace level via labels
- Three modes: `enforce` (block), `audit` (log), `warn` (alert)
- Three profiles: `privileged`, `baseline`, `restricted`

### Service CIDR vs VPC CIDR
- **VPC CIDR**: Real IPs for nodes and pods (AWS networking layer)
- **Service CIDR**: Virtual IPs for load balancing (Kubernetes abstraction)
- ClusterIPs are not routable outside the cluster
- kube-proxy uses iptables NAT to route Service IPs to Pod IPs

### Network Policies
- Define ingress/egress rules for pods
- Use label selectors for pod and namespace targeting
- Require CNI plugin support for enforcement
- AWS VPC CNI has limited support (requires Network Policy add-on)

### Terraform Best Practices
- Use remote state (S3 backend) for team collaboration
- Separate infrastructure phases (PHASE1: cluster, PHASE2: security)
- Use variables for reusability
- Enable lifecycle rules to prevent accidental deletion

## 📖 References

- [EKS Best Practices - Security](https://aws.github.io/aws-eks-best-practices/security/docs/)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [AWS VPC CNI Network Policies](https://docs.aws.amazon.com/eks/latest/userguide/cni-network-policy.html)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

## 📝 Version History

- **2025-11-14**: Initial cluster deployment with PSA, network policies, and KMS encryption
- **EKS Version**: 1.31.13
- **Kubernetes API**: v1.31
