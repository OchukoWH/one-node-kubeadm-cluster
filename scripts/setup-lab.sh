#!/usr/bin/env bash

set -e

echo "Setting up lab..."
echo "Cloning one-node-kubeadm-cluster repository..."
git clone https://github.com/OchukoWH/one-node-kubeadm-cluster.git

echo "Setting up one-node-kubeadm-cluster..."
cd one-node-kubeadm-cluster

echo "Bringing up the lab..."
vagrant up
vagrant ssh master

