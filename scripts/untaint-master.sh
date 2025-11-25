#!/bin/bash
set -e

MASTER_IP=${1:-"192.168.56.30"}

# Set the kubeconfig location (adjust if needed)
KUBECONFIG_PATH="/home/vagrant/.kube/config"

export KUBECONFIG="${KUBECONFIG_PATH}"

echo "=== Detecting master/control-plane node ==="
NODE_NAME=$(kubectl get nodes -o wide --no-headers | awk -v ip="${MASTER_IP}" '$6 == ip {print $1}' | head -n 1)
if [ -z "$NODE_NAME" ]; then
    NODE_NAME=$(kubectl get nodes --no-headers | awk 'NR==1{print $1}')
fi

if [ -z "$NODE_NAME" ]; then
    echo "ERROR: No nodes found!"
    exit 1
fi

echo "Node detected: $NODE_NAME"

echo "=== Checking current taints ==="
kubectl describe node "$NODE_NAME" | grep -i taints || echo "No taints found."

echo "=== Removing control-plane taints ==="
kubectl taint nodes "$NODE_NAME" node-role.kubernetes.io/control-plane- || true

echo "=== Verifying taints ==="
kubectl describe node "$NODE_NAME" | grep -i taints || echo "Taints successfully removed!"

echo "=== Done ==="

