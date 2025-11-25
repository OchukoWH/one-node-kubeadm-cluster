# One-Node kubeadm Cluster

This project spins up a single Ubuntu 22.04 VM with Vagrant and builds a Kubernetes control-plane node with `kubeadm`. The node is automatically untainted so you can schedule user workloads on it, making it ideal for local security experiments or demos. The upstream repository lives at [OchukoWH/one-node-kubeadm-cluster](https://github.com/OchukoWH/one-node-kubeadm-cluster.git).

## What Gets Provisioned

- VirtualBox VM named `master` with 4 GB RAM, 2 vCPUs, and private network IP defined in the `Vagrantfile`.
- Base OS hardening: swap disabled, containerd configured for systemd cgroups, kubelet pinned to Kubernetes v1.28 repositories.
- Networking prerequisites: `br_netfilter` persistence plus IP forwarding and bridge sysctl entries.
- Cluster bootstrap: `kubeadm init` advertises and endpoints on the configured master IP, Calico CNI is installed, and kubeconfig is copied for both `root` and `vagrant`.
- Post-setup customization: master taints are removed so the control-plane node can schedule regular pods.

Each provisioning step is handled by the shell scripts under `scripts/`, and every script now accepts the master IP passed from the `Vagrantfile` to keep configuration in sync.

## Usage

1. **Prerequisites**
   - Install VirtualBox and Vagrant.
   - Clone this repository to a local path.

2. **Configure (optional)**
   - Edit `MASTER_IP` inside the `Vagrantfile` if you need a different private network address. The value will be propagated automatically to every provisioning script.

3. **Create the cluster**
   ```bash
   cd /Users/macbook/bare-metal-projects/kubernetes-security/one-node-kubeadm-cluster
   vagrant up
   ```
   Vagrant will boot the VM, run the provisioning scripts, initialize Kubernetes, install Calico, and untaint the node.

4. **Access the cluster**
   ```bash
   vagrant ssh master
   kubectl get nodes
   ```
   The kubeconfig for the `vagrant` user is preconfigured at `/home/vagrant/.kube/config` and `KUBECONFIG` is exported in `.bashrc`.

5. **Re-run provisioning (optional)**
   ```bash
   vagrant provision master
   ```

6. **Clean up**
   ```bash
   vagrant destroy -f
   ```

## Verifying

Inside the VM you can confirm Calico pods and the untainted node:

```
kubectl get pods -A
kubectl describe node master | grep -i taints
```

You should see Calico components running and either `No taints.` or an empty taints list, indicating that the control-plane node is ready for workloads.

