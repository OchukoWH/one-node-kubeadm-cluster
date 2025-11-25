#!/bin/bash
set -e

MASTER_IP=${1:-"192.168.56.30"}

echo "=== Checking if br_netfilter module is loaded ==="
if lsmod | grep -q br_netfilter; then
    echo "br_netfilter module is loaded"
    MODULE_LOADED=true
else
    echo "WARNING: br_netfilter module not loaded"
    MODULE_LOADED=false
fi

echo "=== Loading br_netfilter if needed ==="
if [ "$MODULE_LOADED" = false ]; then
    modprobe br_netfilter
    echo "Loaded br_netfilter kernel module"

    echo "=== Making br_netfilter module persistent ==="
    mkdir -p /etc/modules-load.d
    if ! grep -qx "br_netfilter" /etc/modules-load.d/k8s.conf 2>/dev/null; then
        echo "br_netfilter" >> /etc/modules-load.d/k8s.conf
        echo "Added br_netfilter to /etc/modules-load.d/k8s.conf"
    fi
fi

echo "=== Verifying interface with IP ${MASTER_IP} ==="
if ip -4 addr show | grep -q "${MASTER_IP}"; then
    echo "Master IP ${MASTER_IP} detected on local interfaces"
else
    echo "WARNING: Master IP ${MASTER_IP} not yet assigned to any interface"
fi

echo "=== Enabling IP forwarding ==="
sysctl -w net.ipv4.ip_forward=1

echo "=== Enabling bridge-nf-call-iptables ==="
sysctl -w net.bridge.bridge-nf-call-iptables=1

echo "=== Making sysctl settings persistent ==="
cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

chmod 644 /etc/sysctl.d/k8s.conf

echo "Reloading sysctl settings..."
sysctl --system

echo "=== All tasks completed successfully ==="

