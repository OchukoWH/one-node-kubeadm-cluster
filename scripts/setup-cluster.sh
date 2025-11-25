#!/bin/bash
set -e

MASTER_IP=${1:-"192.168.56.30"}
POD_CIDR="192.168.0.0/16"
VAGRANT_HOME="/home/vagrant"

echo "=== Resetting kubeadm (safe even if not initialized) ==="
kubeadm reset -f || true

echo "=== Running kubeadm init ==="
if [ ! -f /etc/kubernetes/admin.conf ]; then
    kubeadm init \
        --pod-network-cidr="${POD_CIDR}" \
        --apiserver-advertise-address="${MASTER_IP}" \
        --control-plane-endpoint="${MASTER_IP}"
else
    echo "/etc/kubernetes/admin.conf already exists, skipping kubeadm init"
fi

echo "=== Configuring kubeconfig for root user ==="
mkdir -p /root/.kube
cp -f /etc/kubernetes/admin.conf /root/.kube/config
chmod 600 /root/.kube/config
chown root:root /root/.kube/config

echo "=== Configuring kubeconfig for vagrant user ==="
mkdir -p ${VAGRANT_HOME}/.kube
cp -f /etc/kubernetes/admin.conf ${VAGRANT_HOME}/.kube/config
chmod 600 ${VAGRANT_HOME}/.kube/config
chown vagrant:vagrant ${VAGRANT_HOME}/.kube/config

echo "=== Ensuring KUBECONFIG is set in vagrant user's .bashrc ==="
if ! grep -qx 'export KUBECONFIG=$HOME/.kube/config' ${VAGRANT_HOME}/.bashrc; then
    echo 'export KUBECONFIG=$HOME/.kube/config' >> ${VAGRANT_HOME}/.bashrc
fi

echo "=== Enabling and starting kubelet service ==="
systemctl enable kubelet
systemctl start kubelet

echo "=== Waiting for API server to become ready... ==="
sleep 10

echo "=== Installing Calico CNI ==="
sudo -u vagrant KUBECONFIG=${VAGRANT_HOME}/.kube/config \
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo "=== Calico applied successfully ==="

echo "=== Master initialization complete ==="

