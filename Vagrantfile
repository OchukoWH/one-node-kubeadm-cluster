# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Global settings
  config.vm.box = "generic/ubuntu2204"
  config.vm.box_version = "4.3.12"

  # Use default SSH key (so  works)
  config.ssh.insert_key = true

  # Define IP addresses for the cluster
  MASTER_IP = "192.168.56.30"

  # Master Node
  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: MASTER_IP

    master.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = 2
      vb.name = "master"
    end

    # Provision master node
    master.vm.provision "shell", inline: <<-SHELL
      # Fix DNS resolution
      systemctl disable systemd-resolved
      systemctl stop systemd-resolved
      rm -f /etc/resolv.conf
      echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf

      # Test internet connectivity
      if ! ping -c 4 google.com > /dev/null 2>&1; then
        echo "No internet resolution"
        exit 1
      fi

      echo "Internet OK, continuing with master setup..."
    SHELL

    master.vm.provision "shell", path: "scripts/master-provision.sh", args: ["3-nodes-k8s-cluster", "1", MASTER_IP]
    master.vm.provision "shell", path: "scripts/setup-networking.sh", args: [MASTER_IP]
    master.vm.provision "shell", path: "scripts/setup-cluster.sh", args: [MASTER_IP]
    master.vm.provision "shell", path: "scripts/untaint-master.sh", args: [MASTER_IP]
  end

  # Post-provisioning: Update /etc/hosts on all nodes
  config.vm.provision "shell", inline: <<-SHELL, run: "always"
    echo "#{MASTER_IP} master master" >> /etc/hosts
  SHELL
end

