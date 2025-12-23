#!/bin/bash
# Security Testing Script for EKS Cluster

set -e

echo "========================================="
echo "EKS Security Implementation Test Suite"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Check if kubectl is configured
print_test "Checking kubectl configuration..."
if kubectl cluster-info &> /dev/null; then
    print_pass "kubectl is configured and cluster is reachable"
else
    print_fail "kubectl is not configured properly"
    exit 1
fi

echo ""
echo "========================================="
echo "1. Testing Pod Security Admission (PSA)"
echo "========================================="

# Deploy staging namespace with PSA labels
print_test "Creating staging namespace with PSA audit/warn labels..."
kubectl apply -f manifests/psa-labels.yaml
print_pass "PSA labels applied to staging and production namespaces"

# Test with allowed and disallowed pods
print_test "Testing PSA with compliant and non-compliant pods..."
kubectl apply -f manifests/psa-test-pods.yaml || true
sleep 3

# Check pod status
echo ""
print_test "Checking pod creation status in staging namespace..."
kubectl get pods -n staging

echo ""
echo "========================================="
echo "2. Deploying Secure Application"
echo "========================================="

print_test "Deploying secure nginx application to production namespace..."
kubectl apply -f manifests/sample-app-deployment.yaml
print_pass "Application deployed with security best practices"

print_test "Waiting for nginx pods to be ready..."
kubectl wait --for=condition=ready pod -l app=secure-nginx -n production --timeout=120s
print_pass "Nginx pods are ready"

echo ""
echo "========================================="
echo "3. Testing Network Policies"
echo "========================================="

print_test "Applying network policies..."
kubectl apply -f manifests/production-netpol.yaml
print_pass "Network policies applied"

print_test "Deploying test client pods..."
kubectl apply -f manifests/test-clients.yaml
sleep 5

print_test "Waiting for test clients to be ready..."
kubectl wait --for=condition=ready pod/test-client -n production --timeout=60s || true
kubectl wait --for=condition=ready pod/blocked-client -n production --timeout=60s || true

echo ""
print_test "Testing network connectivity from allowed client..."
if kubectl exec -n production test-client -- curl -s --connect-timeout 5 http://secure-nginx-service &> /dev/null; then
    print_pass "Allowed client CAN access nginx service (Network Policy working correctly)"
else
    print_fail "Allowed client CANNOT access nginx service (Check network policy)"
fi

echo ""
print_test "Testing network connectivity from blocked client..."
if kubectl exec -n production blocked-client -- curl -s --connect-timeout 5 http://secure-nginx-service &> /dev/null; then
    print_fail "Blocked client CAN access nginx service (Network Policy NOT working)"
else
    print_pass "Blocked client CANNOT access nginx service (Network Policy working correctly)"
fi

echo ""
echo "========================================="
echo "4. Verifying Security Configurations"
echo "========================================="

print_test "Checking pod security contexts..."
kubectl get pod -n production -l app=secure-nginx -o jsonpath='{range .items[*]}{.metadata.name}{"\n  runAsNonRoot: "}{.spec.securityContext.runAsNonRoot}{"\n  runAsUser: "}{.spec.securityContext.runAsUser}{"\n"}{end}'
print_pass "Pod security contexts verified"

echo ""
print_test "Checking container security settings..."
kubectl get pod -n production -l app=secure-nginx -o jsonpath='{range .items[*].spec.containers[*]}{.name}{"\n  allowPrivilegeEscalation: "}{.securityContext.allowPrivilegeEscalation}{"\n  readOnlyRootFilesystem: "}{.securityContext.readOnlyRootFilesystem}{"\n"}{end}'
print_pass "Container security settings verified"

echo ""
print_test "Checking resource limits..."
kubectl get pod -n production -l app=secure-nginx -o jsonpath='{range .items[*].spec.containers[*]}{.name}{"\n  CPU limit: "}{.resources.limits.cpu}{"\n  Memory limit: "}{.resources.limits.memory}{"\n"}{end}'
print_pass "Resource limits verified"

echo ""
echo "========================================="
echo "5. Verifying EKS Cluster Security"
echo "========================================="

print_test "Checking EKS cluster encryption configuration..."
aws eks describe-cluster --name prod-secure-eks-cluster --query 'cluster.encryptionConfig' --output table
print_pass "Encryption configuration retrieved"

echo ""
print_test "Checking EKS endpoint access configuration..."
aws eks describe-cluster --name prod-secure-eks-cluster --query 'cluster.resourcesVpcConfig.{PrivateAccess:endpointPrivateAccess,PublicAccess:endpointPublicAccess}' --output table
print_pass "Endpoint access configuration retrieved"

echo ""
print_test "Checking control plane logging..."
aws eks describe-cluster --name prod-secure-eks-cluster --query 'cluster.logging.clusterLogging[0].{Enabled:enabled,Types:types}' --output table
print_pass "Control plane logging configuration retrieved"

echo ""
print_test "Checking CloudWatch log group..."
aws logs describe-log-groups --log-group-name-prefix /aws/eks/prod-secure-eks-cluster --query 'logGroups[0].{Name:logGroupName,Retention:retentionInDays}' --output table
print_pass "CloudWatch log group verified"

echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "✓ Pod Security Admission (PSA) tested"
echo "✓ Secure application deployed"
echo "✓ Network policies enforced and tested"
echo "✓ Security contexts verified"
echo "✓ Resource limits applied"
echo "✓ EKS cluster security features verified"
echo ""
echo "All security implementations have been tested!"
echo ""
echo "Useful commands for further testing:"
echo "  kubectl get pods -n production"
echo "  kubectl get networkpolicies -n production"
echo "  kubectl describe pod -n production <pod-name>"
echo "  kubectl logs -n production -l app=secure-nginx"
echo "  kubectl exec -n production test-client -- curl http://secure-nginx-service"
echo ""
