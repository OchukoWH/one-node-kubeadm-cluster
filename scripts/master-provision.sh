#!/bin/bash
set -euo pipefail

# Get arguments
CLUSTER_NAME=${1:-"3-nodes-k8s-cluster"}
NODE_INDEX=${2:-"1"}
NODE_IP=${3:-"192.168.56.10"}

echo "🚀 Starting master node provisioning..."
echo "Cluster: $CLUSTER_NAME"
echo "Node Index: $NODE_INDEX"
echo "Node IP: $NODE_IP"

# Update package lists
apt-get update

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    wget \
    unzip \
    git

# Configure hostname
hostnamectl set-hostname master-${NODE_INDEX}

# Configure hosts file
cat >> /etc/hosts << EOF
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# Disable swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install containerd
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y containerd.io

# Configure containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Install Kubernetes packages
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Configure kubelet with the provided node IP
echo "KUBELET_EXTRA_ARGS=\"--node-ip=${NODE_IP}\"" > /etc/default/kubelet
systemctl daemon-reload
systemctl enable kubelet

# Install additional tools
apt-get install -y \
    jq \
    htop \
    vim

# Create directories
mkdir -p /etc/kubernetes/manifests
mkdir -p /var/lib/kubelet

# Log completion
echo "Master node ${NODE_INDEX} setup completed at $(date)" >> /var/log/k8s-setup.log

echo "✅ Master node provisioning completed!"
