#!/bin/bash
sudo apt-get update
sudo apt-mark hold grub-pc
sudo apt-get upgrade -y 
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common
# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
sudo apt install -y docker-ce
sudo swapoff -a

# Install kubeadm
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
export IPADR=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
sudo kubeadm init --apiserver-advertise-address=$IP --pod-network-cidr=10.244.0.0/16
sleep 10
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $/home/ubuntu/.kube/config
sudo chown $(id -u):$(id -g) /home/ubuntu/.kube/config
# Allow pods to be scheduled on master
kubectl taint nodes --all node-role.kubernetes.io/master-
# Install flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
sudo mkdir -p /mnt/data/graf-server/
sudo mkdir /mnt/data/prom-alert/
sudo mkdir /mnt/data/prom-server/
