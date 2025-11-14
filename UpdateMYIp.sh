#!/bin/bash

CLUSTER_NAME="prod-secure-eks-cluster"
REGION="us-east-1"

MY_IP=$(curl -s https://checkip.amazonaws.com)
if [[ -z "$MY_IP" ]]; then
  echo "Failed to retrieve public IP."
  exit 1
fi
echo "Current public IP: $MY_IP"

# Get current public CIDRs
CURRENT_CIDRS=$(aws eks describe-cluster \
  --region "$REGION" \
  --name "$CLUSTER_NAME" \
  --query "cluster.resourcesVpcConfig.publicAccessCidrs" \
  --output text)

# Check if IP is already whitelisted
if [[ "$CURRENT_CIDRS" == *"$MY_IP"* ]]; then
  echo "IP $MY_IP is already whitelisted. No update needed."
  exit 0
fi

# Update cluster
aws eks update-cluster-config \
  --region "$REGION" \
  --name "$CLUSTER_NAME" \
  --resources-vpc-config endpointPublicAccess=true,publicAccessCidrs="[$MY_IP/32]"

if [[ $? -eq 0 ]]; then
  echo "EKS cluster updated successfully!"
else
  echo "Failed to update EKS cluster."
  exit 1
fi

